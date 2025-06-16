cd /root

## clear / create the file
echo "" > agg-template.conf

# add sampler nodes to aggregator configs
IFS=',' read -r -a nodes <<< "$COMPUTE_NODES"

for i in "${!nodes[@]}"; do
  node="${nodes[$i]}"
  sampler_name="sampler$((i+1))"
  echo "prdcr_add name=$sampler_name host=$node port=10001 xprt=sock type=active reconnect=20000000" >> agg-template.conf
  echo "prdcr_start name=$sampler_name" >> agg-template.conf
done

# write rest of the agg config file
cat <<EOF >> agg-template.conf
# update policies
updtr_add name=update_all interval=1000000 auto_interval=true
updtr_prdcr_add name=update_all regex=.*
updtr_start name=update_all

# csv configs
load name=store_csv
config name=store_csv path=/root/storage buffer=0
# Schema-specific storage targets
strgp_add name=meminfo-store plugin=store_csv container=memory_metrics schema=meminfo
strgp_add name=vmstat-store plugin=store_csv container=system_metrics schema=vmstat
strgp_add name=loadavg-store plugin=store_csv container=load_metrics schema=loadavg
strgp_add name=procstat2-store plugin=store_csv container=procstat2_metrics schema=procstat2
strgp_add name=procnetdev2-store plugin=store_csv container=procnetdev2_metrics schema=procnetdev2
strgp_add name=procnet-store plugin=store_csv container=procnet_metrics schema=procnet
strgp_add name=netdev-store plugin=store_csv container=netdev_metrics schema=netdev

# Start the storage plugins
strgp_start name=meminfo-store
strgp_start name=vmstat-store
strgp_start name=loadavg-store
strgp_start name=procstat2-store
strgp_start name=procnetdev2-store
strgp_start name=procnet-store
strgp_start name=netdev-store
EOF

# pass through envsubst to generate the final conf
envsubst < agg-template.conf > agg.conf

# start ldmsd - keeping it here so docker-stack.yaml is clean
exec ldmsd.sh ${LDMSD_FLAGS}
