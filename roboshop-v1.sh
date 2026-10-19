#!/bin/bash

ami_id="ami-0055977a6e828a4f4" 
instance_type="t3.micro"
domain_name="gcart.store"
hostedzone_id="Z01591623E51DMT4FH925"

for instance in $@
do
    echo "Creating instance = $instance"
done