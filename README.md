ZHdK Leihs Server-Inventory
===========================


Leihs Prod Deploy
-----------------
* upgrade the `leihs` submodule,
* adjust the configuration if necessary, and
* run `./bin/leihs-prod-deploy`


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



Notes to Server Migration DB-Restore
------------------------------------

```
# on v5
ssh root@zhdk-leihs-prod-v5.ruby.zhdk.ch
rsync -e ssh -Pavz db-backups root@zhdk-leihs-prod-v6.ruby.zhdk.ch:/leihs/var

# local
./bin/leihs-prod-restore-v5-db
```



