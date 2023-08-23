ZHdK Leihs Server-Inventory
===========================


Prod Leihs Deploy
-----------------
* upgrade the `leihs` submodule,
* adjust the configuration if necessary, and


### Manual Deploy

* run `./bin/staging-leihs-deploy`, after success:
* run `./bin/prod-leihs-deploy`

### CI Deploy

* push to the branch 'deploy' respectively `git push origin HEAD:deploy`



ZAPI-Sync Deploy
----------------

* upgrade the `leihs-sync` submodule,
* adjust the configuration if necessary, and
* run `./bin/prod-sync-deploy`

AGW-Auth Deploy
---------------

* upgrade the `agw-auth` submodule,
* adjust the configuration if necessary, and
* run `./bin/prod-agw-auth-deploy`


