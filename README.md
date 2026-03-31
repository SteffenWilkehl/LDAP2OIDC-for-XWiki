# XWiki LDAP to OIDC Converter

> **Maintenance Note:** This script was developed for a specific enterprise migration in 2020. I no longer work with XWiki and do not actively maintain this repository. It is provided as-is as a reference for similar legacy migrations. PRs are welcome, but I do not provide support.

A Bash script to migrate existing XWiki users from LDAP to the XWiki OpenID Connect (OIDC) Authenticator.

## Background

**Historically (ca. 2020):** When migrating an XWiki instance from LDAP to OIDC, the native plugin lacked auto-mapping features. This script was required to convert user profile objects to prevent permission loss and duplicate profiles.

**Today:** Modern versions of the XWiki OIDC plugin can map users on their first login. However, this script is still useful for pre-migrations. It allows you to bulk-convert all user objects before switching to OIDC, ensuring all profiles and rights are mapped beforehand.

## Prerequisites

* Linux/Unix environment with `bash`
* `curl`
* Active XWiki instance with admin access

## Usage

Run the script with the required parameters. If you omit them, the script will prompt you interactively.

### Syntax
```bash
./xwiki_ldap_to_oidc.sh -u <AdminUser> -p <AdminPassword> -x <XWikiURL> -i <OIDCIssuer>
