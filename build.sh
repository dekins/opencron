#!/bin/bash

echo -ne "\033[0;32m"
cat<<EOT

      --------------------------------------------
    /                                              \\
   /   ___  _ __   ___ _ __   ___ _ __ ___  _ __    \\
  /   / _ \| '_ \ / _ \ '_ \ / __| '__/ _ \| '_ \\    \\
 /   | (_) | |_) |  __/ | | | (__| | | (_) | | | |    \\
 \\    \___/| .__/ \___|_| |_|\___|_|  \___/|_| |_|    /
  \\        |_|                                       /
   \\                                                /
    \\       --opencron,Let's crontab easy!         /
      --------------------------------------------

EOT
echo -ne "\033[m";

# OS specific support.  $var _must_ be set to either true or false.
cygwin=false
darwin=false
os400=false
case "`uname`" in
CYGWIN*) cygwin=true;;
Darwin*) darwin=true;;
OS400*) os400=true;;
esac

# resolve links - $0 may be a softlink
PRG="$0"

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done

# Get standard environment variables
PRGDIR=`dirname "$PRG"`

WORKDIR="`readlink -f ${PRGDIR}`"

MAVEN_URL="http://mirror.bit.edu.cn/apache/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz";

MAVEN_NAME="apache-maven-3.5.0-bin"

UNPKG_MAVEN_NAME="apache-maven-3.5.0";

OPENCRON_VERSION="1.1.0-RELEASE";

BUILD_HOME=${WORKDIR}/build

[ ! -d ${BUILD_HOME} ] && mkdir ${BUILD_HOME}

[ ! -d ${BUILD_HOME}/dist ] && mkdir ${BUILD_HOME}/dist/
rm -rf ${BUILD_HOME}/dist/*

function echo_r () {
    # Color red: Error, Failed
    [ $# -ne 1 ] && return 1
    echo -e "[\033[32mopencron\033[0m] \033[31m$1\033[0m"
}

function echo_g () {
    # Color green: Success
    [ $# -ne 1 ] && return 1
    echo -e "[\033[32mopencron\033[0m] \033[32m$1\033[0m"
}

function echo_y () {
    # Color yellow: Warning
    [ $# -ne 1 ] && return 1
    echo -e "[\033[32mopencron\033[0m] \033[33m$1\033[0m"
}

USER="`id -un`"
LOGNAME="$USER"
if [ $UID -ne 0 ]; then
    echo_y "WARNING: Running as a non-root user, \"$LOGNAME\". Functionality may be unavailable. Only root can use some commands or options"
fi

#check java exists.
java >/dev/null 2>&1

if [ $? -ne 1 ];then
  echo_r "ERROR: java is not install,please install java first!"
  exit 1;
fi

#check maven exists
mvn -h >/dev/null 2>&1

if [ $? -ne 1 ]; then
    echo_y "WARNING:maven is not install!"
    echo_g "checking network connectivity ... "
    net_check_ip=114.114.114.114
    ping_count=2
    ping -c ${ping_count} ${net_check_ip} >/dev/null
    retval=$?
    if [ ${retval} -ne 0 ] ; then
        echo_r "ERROR:network is blocked! please check your network!build error! bye!"
        exit 1
    elif [ ${retval} -eq 0 ]; then
        echo_g "check network connectivity passed! "
        if [ ! -x "${BUILD_HOME}/${UNPKG_MAVEN_NAME}" ] ; then
             echo_y "download maven Starting..."
             wget -P ${BUILD_HOME} $MAVEN_URL && {
                echo_g "download maven successful!";
                echo_g "install maven Starting"
                tar -xzvf ${BUILD_HOME}/${MAVEN_NAME}.tar.gz -C ${BUILD_HOME}
                echo "
<?xml version=\"1.0\" encoding=\"UTF-8\"?>

<settings xmlns=\"http://maven.apache.org/SETTINGS/1.0.0\"
          xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
          xsi:schemaLocation=\"http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd\">

  <mirrors>
    <mirror>
      <id>nexus-aliyun</id>
      <mirrorOf>*</mirrorOf>
      <name>Nexus aliyun</name>
      <url>http://maven.aliyun.com/nexus/content/groups/public</url>
    </mirror>
  </mirrors>

</settings>" > ${BUILD_HOME}/${UNPKG_MAVEN_NAME}/conf/settings.xml
                OPENCRON_MAVEN=${BUILD_HOME}/${UNPKG_MAVEN_NAME}/bin/mvn
             }
        else
             OPENCRON_MAVEN=${BUILD_HOME}/${UNPKG_MAVEN_NAME}/bin/mvn
        fi
    fi
fi

if [ "$OPENCRON_MAVEN"x = ""x ]; then
    OPENCRON_MAVEN="mvn";
fi

echo_g "build opencron Starting...";

$OPENCRON_MAVEN clean install -Dmaven.test.skip=true;

retval=$?

if [ ${retval} -ne 0 ] ; then
    echo_r "build opencron failed! please try again "
    exit 1
else
    cp ${WORKDIR}/opencron-agent/target/opencron-agent-${OPENCRON_VERSION}.tar.gz ${BUILD_HOME}/dist/
    cp ${WORKDIR}/opencron-server/target/opencron-server.war ${BUILD_HOME}/dist/
    echo_g "build opencron successfully! please goto ${BUILD_HOME}/dist"
    exit 0
fi
