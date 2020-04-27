# Velero
Velero is powerfull Kubernetes backup tool. It simplify many operation tasks.

## Why Velero
With Velero it's easier to:
* Choose what to backup(objects, volumes or everything)
* Choose what NOT to backup(e.g. secrets)
* Schedule cluster backups
* Store backups on remote storage
* Fast disaster recovery process

### Install and configure Velero
1)Download latest version of [Velero](https://github.com/vmware-tanzu/velero/releases)

2)Create AWS credential file:
```
[default]
aws_access_key_id=<your AWS access key ID>
aws_secret_access_key=<your AWS secret access key>
```

3)Create s3 bucket for etcd-backups
```aws s3 mb s3://kubernetes-velero-backup-bucket```

4)Install velero to kubernetes cluster:
```
velero install --provider aws --plugins velero/velero-plugin-for-aws:v1.0.0 --bucket kubernetes-velero-backup-bucket --secret-file ./aws-iam-creds --backup-location-config region=us-east-1 --snapshot-location-config region=us-east-1
```
>Note: we use s3 plugin to access remote storage. Velero support many different [storage providers](https://velero.io/plugins/). See which works for you best.

### Schedule automated backups
1)Schedule daily backups:
```velero schedule create <SCHEDULE NAME> --schedule "0 7 * * *"```

2)Create a backup manually:
```velero backup create <BACKUP NAME>```

### Disaster Recovery 
>Note: You might need to re-install Velero in case of full etcd data loss.

When Velero is up disaster recovery process are simple and straightforward:

1)Update your backup storage location to read-only mode
```
kubectl patch backupstoragelocation <STORAGE LOCATION NAME> \
    --namespace velero \
    --type merge \
    --patch '{"spec":{"accessMode":"ReadOnly"}}'
```
By default, ```<STORAGE LOCATION NAME>``` is expected to be named ```default```, however the name can be changed by specifying ```--default-backup-storage-location``` on velero server.

2)Create a restore with your most recent Velero Backup:
```
velero restore create --from-backup <SCHEDULE NAME>-<TIMESTAMP>
```

3)When ready, revert your backup storage location to read-write mode:
```
kubectl patch backupstoragelocation <STORAGE LOCATION NAME> \
   --namespace velero \
   --type merge \
   --patch '{"spec":{"accessMode":"ReadWrite"}}'
```