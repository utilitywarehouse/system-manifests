# Setting aliases for the most used kafka commands
alias kafka-topics='kafka-topics.sh --bootstrap-server ${SEED_BROKERS} --command-config ${KAFKA_CMD_CONFIG}'
alias kafka-reassign-partitions='kafka-reassign-partitions.sh --bootstrap-server ${SEED_BROKERS} --command-config ${KAFKA_CMD_CONFIG}'
alias kafka-consumer-groups='kafka-consumer-groups.sh --bootstrap-server ${SEED_BROKERS} --command-config ${KAFKA_CMD_CONFIG}'
alias kafka-configs='kafka-configs.sh --bootstrap-server ${SEED_BROKERS} --command-config ${KAFKA_CMD_CONFIG}'
alias kafka-get-offsets='kafka-get-offsets.sh --bootstrap-server ${SEED_BROKERS} --command-config ${KAFKA_CMD_CONFIG}'
