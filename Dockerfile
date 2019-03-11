FROM debian:stable

LABEL maintainer="Michael Nival <docker@mn-home.fr>" \
	name="debian-apache" \
	description="Debian Stable with apache2 supervisor" \
	docker.cmd="docker run -d -p 80:80 -v /etc/apache2:/etc/apache2 -v /var/log/apache2:/var/log/apache2 --hostname apache2 --name apache2 mnival/debian-apache2"

RUN printf "deb http://ftp.debian.org/debian/ stable main\ndeb http://ftp.debian.org/debian/ stable-updates main\ndeb http://security.debian.org/ stable/updates main\n" >> /etc/apt/sources.list.d/stable.list && \
	cat /dev/null > /etc/apt/sources.list && \
	export DEBIAN_FRONTEND=noninteractive && \
	apt update && \
	apt -y --no-install-recommends full-upgrade && \
	apt install -y --no-install-recommends apache2 supervisor && \
	echo "Europe/Paris" > /etc/timezone && \
	rm /etc/localtime && \
	dpkg-reconfigure tzdata && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/alternatives.log /var/log/dpkg.log /var/log/apt/ /var/cache/debconf/*-old

ADD supervisor-apache2.conf /etc/supervisor/conf.d/apache2.conf

RUN a2enmod rewrite && \
	sed -i 's/^ServerTokens.*/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf && \
	sed -i 's/ServerSignature.*/ServerSignature Off/g' /etc/apache2/conf-available/security.conf && \
	printf "<Directory /var/www/html>\n\tOptions FollowSymLinks\n\tAllowOverride All\n\tRequire all granted\n</Directory>\n" > /etc/apache2/conf-available/directory-var-www-html.conf && \
	a2enconf directory-var-www-html

ADD event-supervisor/event-supervisor.sh /usr/local/bin/event-supervisor.sh
ADD event-supervisor/supervisor-eventlistener.conf /etc/supervisor/conf.d/eventlistener.conf
RUN sed -i 's/^\(logfile.*\)/#\1/' /etc/supervisor/supervisord.conf

VOLUME ["/etc/apache2", "/var/log/apache2"]

EXPOSE 80

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
