{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
services.sssd.enable = true;
services.sssd.environmentFile = "/stateful/sys-data/
services.sssd.config = ''

[sssd]
config_file_version = 2
reconnection_retries = 3
domains = ${ldap.domain}
services = nss, pam, ssh

[pam]
reconnection_retries = 3

[domain/${ldap.domain}]
cache_credentials = True
id_provider = ldap
chpass_provider = ldap
auth_provider = ldap
access_provider = ldap
ldap_uri = ldaps://${authentik.company}:636

ldap_schema = rfc2307bis
ldap_search_base = ${ldap.baseDN}
ldap_user_search_base = ou=users,${ldap.baseDN}
ldap_group_search_base = ${ldap.baseDN}

ldap_user_object_class = user
ldap_user_name = cn
ldap_group_object_class = group
ldap_group_name = cn

# Optionally, filter logins to only a specific group
#ldap_access_order = filter
#ldap_access_filter = memberOf=cn=authentik Admins,ou=groups,${ldap.baseDN}

ldap_default_bind_dn = cn=${sssd.serviceAccount},ou=users,${ldap.baseDN}
ldap_default_authtok = ${sssd.serviceAccountToken}
'';

}
