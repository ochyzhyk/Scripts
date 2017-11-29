echo off
IF "%JAVA_HOME%" == "" (
    echo set JAVA_HOME to continue the operation     
) ELSE (    
    java -cp "lib/*;config/" com.vmware.xvcprov.CrossVCProvClient %*
) 
