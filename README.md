ATVProxy
========

Certificates
------------
```
openssl req -new -nodes -newkey rsa:2048 -out trailers.pem -keyout trailers.key -x509 -days 7300 -subj "/C=US/CN=trailers.apple.com"
openssl x509 -in trailers.pem -outform der -out trailers.cer && cat trailers.key >> trailers.pem
```

Profile
-------
```
  http://<server-ip>/profile.cert
```