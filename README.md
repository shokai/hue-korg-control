# Hue-KorgNano Controll
Controll [Philips Hue](http://www.meethue.com/) with [Korg nanoKontrol](http://www.korg.co.jp/Product/Discontinued/nano/)

- https://github.com/shokai/hue-korg-control

[![Circle CI](https://circleci.com/gh/shokai/hue-korg-control.svg?style=svg)](https://circleci.com/gh/shokai/hue-korg-control)

![GIF](http://gyazo.com/0a2e44b980acbc68bfc7d6afec15f289.gif)

## Mapping

- knob: hue
- slider: brightness
- button 1-9: set saturation 0
- button 10-18: blink(lselect)
- button loop: colorloop effect
- button play: lselect alert

## Install Dependencies

    % npm install


## Run

    % npm start

    % DEBUG=* npm start  # for debug


## Install as Service

    % gem install foreman

for launchd (Mac OSX)

    % sudo foreman export launchd /Library/LaunchDaemons/ --app hue-korg -u `whoami`
    % sudo launchctl load -w /Library/LaunchDaemons/hue-korg-main-1.plist


for upstart (Ubuntu)

    % sudo foreman export upstart /etc/init/ --app hue-korg -d `pwd` -u `whoami`
    % sudo service hue-korg start
