echo "RESTARTING AEROSPIKE SERVER"
#service aerospike restart
sleep 30
/etc/init.d/aerospike restart
echo $?
