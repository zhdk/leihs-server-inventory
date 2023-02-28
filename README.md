ZHdK Leihs Server-Inventory
===========================


Leihs Prod Deploy
-----------------
* upgrade the `leihs` submodule,
* adjust the configuration if necessary, and


### Manual Deploy

* run `./bin/leihs-staging-deploy`, after success:
* run `./bin/leihs-prod-deploy`

### CI Deploy

* push to the branch 'deploy' respectively `git push origin HEAD:deploy`



ZAPI-Sync Deploy
----------------

* upgrade the `leihs-sync` submodule,
* adjust the configuration if necessary, and
* run `./bin/sync-prod-deploy`

AGW-Auth Deploy
---------------

* upgrade the `agw-auth` submodule,
* adjust the configuration if necessary, and
* run `./bin/agw-auth-prod-deploy`


