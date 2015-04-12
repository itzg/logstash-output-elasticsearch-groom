# logstash-output-elasticsearch-groom

## On Windows, with Logstash 1.5.0.rc2

Edit the `Gemfile` under the distribution adding a line like:

```
gem "logstash-output-elasticsearch_groom", :path => "C:\\Users\\YOURNAME\\git\\logstash-output-elasticsearch-groom"
```

and then run

```
bin\plugin.bat install --no-verify
```

This workaround was obtained from [this issue comment](https://github.com/elastic/logstash/issues/2779#issuecomment-77927682).