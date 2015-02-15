# Hue-KorgNano Controll
Controll [Philips Hue](http://www.meethue.com/) with [Korg nanoKontrol](http://www.korg.co.jp/Product/Discontinued/nano/)

- https://github.com/shokai/hue-korg-control


## Mapping

- knob: hue
- slider: brightness


## Install Dependencies

    % npm install


## Run

    % npm start

    % DEBUG=hue-korg* npm start  # for debug


## Install as Service

    % gem install foreman

for launchd (Mac OSX)

    % sudo foreman export launchd /Library/LaunchDaemons/ --app hue-korg -u `whoami`
    % sudo launchctl load -w /Library/LaunchDaemons/hue-korg-main-1.plist


for upstart (Ubuntu)

    % sudo foreman export upstart /etc/init/ --app hue-korg -d `pwd` -u `whoami`
    % sudo service hue-korg start
