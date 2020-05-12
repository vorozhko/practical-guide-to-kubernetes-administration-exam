# Backup with etcdctl

etcdctl is command line tool to manage etcd server and it's date.
command to make a backup is:

## Making a backup

```bash
ETCDCTL_API=3 etcdctl --endpoints $ENDPOINT snapshot save snapshot.db
```

command to restore snapshot is:

```bash
ETCDCTL_API=3 etcdctl snapshot restore snapshot.db
```

> Note: You might need to specify paths to certificate keys in order to access etcd server api with etcdctl.

## Store backup at remote storage

It's important to backup data on remote storage like s3. It's guarantee that a copy of etcd data will be available even if control plane volume is unaccessible or corrupted.

### Step 1: Make an s3 bucket:

```bash
aws s3 mb etcd-backup
```

### Step 2: Copy snapshot.db to s3 with new filename:

```bash
filename=`date +%F-%H-%M`.db
aws s3 cp ./snapshot.db s3://etcd-backup/etcd-data/$filename
```

### Step 3: Setup s3 object expiration to clean up old backup files

```bash
aws s3api put-bucket-lifecycle-configuration --bucket my-bucket --life
cycle-configuration  file://lifecycle.json
```

Example of lifecycle.json which transition backups to s3 Glacier:

```json
{
              "Rules": [
                  {
                      "ID": "Move rotated backups to Glacier",
                      "Prefix": "etcd-data/",
                      "Status": "Enabled",
                      "Transitions": [
                          {
                              "Date": "2015-11-10T00:00:00.000Z",
                              "StorageClass": "GLACIER"
                          }
                      ]
                  },
                  {
                      "Status": "Enabled",
                      "Prefix": "",
                      "NoncurrentVersionTransitions": [
                          {
                              "NoncurrentDays": 2,
                              "StorageClass": "GLACIER"
                          }
                      ],
                      "ID": "Move old versions to Glacier"
                  }
              ]
          }

```

## Restore etcd backup

>See etcdadm tool

Steps are:

* List all members
* Remove failed member
* Add new member
* In case several members failed restore them one by one
