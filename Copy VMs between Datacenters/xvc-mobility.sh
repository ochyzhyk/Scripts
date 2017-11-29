if [ -z ${JAVA_HOME} ]; then
        echo "set JAVA_HOME to continue the operation"
        exit -1
else
	echo ${JAVA_HOME}
	export PATH=$PATH:$JAVA_HOME/bin/
	java -cp ".:lib/*:config/*" com.vmware.xvcprov.CrossVCProvClient $@
fi
