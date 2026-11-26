SET PATH=C:\JDK\25\bin;%PATH%
SET JAVA=C:\JDK\25
SET JAVA_HOME=%JAVA%
SET JRE_HOME=%JAVA%
java --version
call mvnw.cmd clean package
java -jar target/eks-demo-0.0.1-SNAPSHOT.jar