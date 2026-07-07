
#!/bin/bash
BUCKET='s3://Nom_Bucket_S3'
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR='/tmp/backup_'$TIMESTAMP

mkdir -p $BACKUP_DIR

cp /var/log/auth.log $BACKUP_DIR/

tar czf /tmp/payflow_backup_$TIMESTAMP.tar.gz -C /tmp backup_$TIMESTAMP

/usr/local/bin/aws s3 cp /tmp/payflow_backup_$TIMESTAMP.tar.gz $BUCKET/daily/

rm -rf $BACKUP_DIR /tmp/payflow_backup_$TIMESTAMP.tar.gz

echo '[OK] Backup uploaded to S3 at' $(date)
