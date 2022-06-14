# ocp4_catsrc_operators
Bash script to prune index and mirror OpenShift Operators

Most parameters are in _.json_ file. These two parameters are command line arguments:

* FN_CATSRC ($1)
* STAGING_REGISTRY ($2)

The rest are provided in "`catalog-source.json` file. Here we are specifying apicurio-registry, yaks packages from the and dynatrace from the respective Red Hat community and certified indexes:

```
{
  "registry_folder": "ocp48-operators",
  "version": "v4.8",
  "publisher": "My Team",
  "registries": [
    { 
      "name": "registry.redhat.io/redhat/community-operator-index",
      "label": "community",
      "packages": [
        "apicurio-registry",
        "yaks"
      ]
    },
    {
      "name": "registry.redhat.io/redhat/redhat-operator-index",
      "label": "redhat",
      "packages": []
    },
    {
      "name": "registry.redhat.io/redhat/certified-operator-index",
      "label": "certified",
      "packages": [
        "dynatrace-operator"
      ]
    }
  ]
}

```


Specifying _DRYRUN=y_ as an environment variable will give example run:

```
$ DRYRUN=y ./mirror.sh 

=========== Mirroring v4.8 Manifests ===========

******* Mirror registry.redhat.io/redhat/community-operator-index ******
cp catsrc-packages.json to logs/ocp48-operators/community
tail logs/ocp48-operators/community/community-20220614.log for progress

==== ..Creating Index Image: ====

.. sudo /usr/local/bin/opm index prune -c docker -f registry.redhat.io/redhat/community-operator-index:v4.8 -p apicurio-registry -t registry.internal.lan/ocp48-operators/prunedindex-community:v4-8


==== ..Push Image: ====

.. sudo /usr/bin/docker push registry.internal.lan/ocp48-operators/prunedindex-community:v4-8

The push refers to repository [registry.internal.lan/ocp48-operators/prunedindex-community]
An image does not exist locally with the tag: registry.internal.lan/ocp48-operators/prunedindex-community

==== ..Mirror Manifests:

.. sudo /usr/local/bin/oc adm catalog mirror registry.internal.lan/ocp48-operators/prunedindex-community:v4-8 registry.internal.lan/ocp48-operators --max-components=5 --insecure=true --index-filter-by-os="linux/amd64" --to-manifests=logs/ocp48-operators/community


******* Mirror registry.redhat.io/redhat/certified-operator-index ******
cp catsrc-packages.json to logs/ocp48-operators/certified
tail logs/ocp48-operators/certified/certified-20220614.log for progress

==== ..Creating Index Image: ====

.. sudo /usr/local/bin/opm index prune -c docker -f registry.redhat.io/redhat/certified-operator-index:v4.8 -p dynatrace-operator -t registry.internal.lan/ocp48-operators/prunedindex-certified:v4-8


==== ..Push Image: ====

.. sudo /usr/bin/docker push registry.internal.lan/ocp48-operators/prunedindex-certified:v4-8

The push refers to repository [registry.internal.lan/ocp48-operators/prunedindex-certified]
An image does not exist locally with the tag: registry.internal.lan/ocp48-operators/prunedindex-certified

==== ..Mirror Manifests:

.. sudo /usr/local/bin/oc adm catalog mirror registry.internal.lan/ocp48-operators/prunedindex-certified:v4-8 registry.internal.lan/ocp48-operators --max-components=5 --insecure=true --index-filter-by-os="linux/amd64" --to-manifests=logs/ocp48-operators/certified

```

Logs are put into log directory, ie:

```
$ find logs
logs
logs/ocp48-operators
logs/ocp48-operators/community
logs/ocp48-operators/community/community-20220614.log
logs/ocp48-operators/community/mapping.txt
logs/ocp48-operators/community/catalogSource.yaml
logs/ocp48-operators/community/catsrc-packages.json
logs/ocp48-operators/community/imageContentSourcePolicy.yaml
logs/ocp48-operators/certified
logs/ocp48-operators/certified/mapping.txt
logs/ocp48-operators/certified/catalogSource.yaml
logs/ocp48-operators/certified/catsrc-packages.json
logs/ocp48-operators/certified/imageContentSourcePolicy.yaml
logs/ocp48-operators/certified/certified-20220614.log

```
