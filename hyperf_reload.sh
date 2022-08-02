#!/bin/bash

path="/data/www/wwwroot/gz-mini-program"
echo "更新代码"
cd $path
git pull;

php "$path/bin/hyperf.php" doc:sync

if [ "$(netstat -na | grep LISTEN | grep 9501)" ]; then
        export port=9502
        close=9501
else
        export port=9501
        close=9502
fi

if [ "$1" != "close" ]; then
        echo "热启动开始";
        nohup php "$path/bin/hyperf.php" start &
	if [ "$?" != "0" ]; then
		echo "热启动失败 port = $port";
		exit 0;
	fi
	sstr=$(echo -e "\n")
	echo $sstr
	echo "proxy_pass http://127.0.0.1:$port;" > "$path/runtime/nginx_proxy.conf"

        for (( i=0 ; i < 10 ; i++ ))
        do
		if [ "$(netstat -na | grep LISTEN | grep $port)" ]; then
                        sudo nginx -s reload
			sleep 1
                        echo "启动成功 port = $port";
                        echo "正在关闭 port = $close";
                        if [ "$(netstat -na | grep LISTEN | grep $close)" ]; then
                                kill $(cat "$path/runtime/hyperf$close.pid")
                        fi
                        echo "热启动完成";
                        exit 0;
                fi
		sleep 1
        done
fi
echo "热启动失败 port = $port";
