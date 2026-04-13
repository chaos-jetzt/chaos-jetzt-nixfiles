{ config, pkgs, ... }:

let
  populate_content = pkgs.writeText "populate_content.ldif" ''
    dn: dc=chaos, dc=jetzt
    dc: chaos
    o: chaos.jetzt
    objectClass: top
    objectclass: organization
    objectclass: dcObject

    dn: ou=People,dc=chaos,dc=jetzt
    changetype: add
    objectClass: organizationalUnit

    dn: ou=Groups,dc=chaos,dc=jetzt
    changetype: add
    objectClass: organizationalUnit
  '';
  init_ldap = pkgs.writeShellScript "init-ldap" ''
    export PATH=${config.services.openldap.package}/bin:$PATH
    export LDAP_ALREADY_EXISTS=68
    ldapadd -c -Y EXTERNAL -H ldapi:/// -f ${populate_content}
    ret=$?
    if [[ $ret -eq $LDAP_ALREADY_EXISTS ]]; then
      echo "Everything already exists"
      exit 0
    fi
    exit $ret
  '';
in {
  sops.secrets = {
    "ldap/admin_password".owner = config.services.openldap.user;
  };

  services.openldap = {
    enable = true;
    urlList = [
      "ldap:///"
      "ldapi:///"
    ];
    settings = {
      attrs.olcLogLevel = [ "stats" ];
      children = let
        root_access = "dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth";
      in{
        "cn=schema".includes = [
            "${pkgs.openldap}/etc/schema/core.ldif"
            "${pkgs.openldap}/etc/schema/cosine.ldif"
            "${pkgs.openldap}/etc/schema/nis.ldif"
            "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
          ];
        "olcDatabase={-1}frontend".attrs = {
          objectClass = [ "olcDatabaseConfig" "olcFrontendConfig" ];
          olcDatabase = "{-1}frontend";
          olcSizeLimit = "500";
          # Allows the local root user to see the running config
          # ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config
          olcAccess = [
            "{0}to * by ${root_access} manage by * break"
            "{1}to dn.exact=\"\" by * read"
            "{2}to dn.base=\"cn=Subschema\" by * read"
          ];
          structuralObjectClass = "olcDatabaseConfig";
        };
        /* "olcBackend={0}mdb".attrs = {
          objectClass = "olcBackendConfig";
          olcBackend = "{0}config";
        }; */
        "olcDatabase={0}config".attrs = {
          objectClass = "olcDatabaseConfig";
          olcDatabase = "{0}config";
          # Allows the local root user to see the running config
          # ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config
          olcAccess = [
            "{0}to * by ${root_access} manage by * break"
          ];
        };
        "olcDatabase={1}mdb".attrs = {
          objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];

          olcDatabase = "{1}mdb";
          olcDbDirectory = "/var/lib/openldap/data";

          olcSuffix = "dc=chaos,dc=jetzt";

          olcRootDN = "cn=admin,dc=chaos,dc=jetzt";
          olcRootPW.path = config.sops.secrets."ldap/admin_password".path;

          olcLastMod = "TRUE";
          olcdbcheckpoint = "512 30";

          olcDbIndex = [
            "objectClass eq"
            "cn,uid eq"
            "uidNumber,gidNumber eq"
            "member,memberUid eq"
          ];
          olcAccess = [
            ''{0}to attrs=userPassword by self write by anonymous auth by * none''
            ''{1}to attrs=shadowLastChange by self write by * read''
          ];
        };
      };
    };
  };

  systemd.services.openldap.serviceConfig.ExecStartPost = [
    "!${init_ldap}"
  ];
}
