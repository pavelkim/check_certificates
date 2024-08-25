#shellcheck shell=sh

Describe "Prometheus functions"

  Include ../check_certificates.sh

  Describe "generate_prometheus_metrics()"

    now_unix_epoch=$(date +%s)

    full_result=(
      "broken-domain.com ${now_unix_epoch} ${now_unix_epoch} error"
      "expired-ssl.com 1696896000 $(( now_unix_epoch - 60*60*24 )) ok"
      "zero-days-left-ssl.com 1696896000 ${now_unix_epoch} ok"
      "one-day-left-ssl.com 1696896000 $((now_unix_epoch + 60*60*24)) ok"
    )

    It "Generates the Prometheus metrics"
      When call generate_prometheus_metrics "${full_result[@]}"
      The contents of file "/tmp/metrics" should include "HELP check_certificates_expiration Days until HTTPs SSL certificate expires"
      The contents of file "/tmp/metrics" should include 'check_certificates_expiration{domain="broken-domain.com",outcome="error"} 0'
      The contents of file "/tmp/metrics" should include 'check_certificates_expiration{domain="expired-ssl.com",outcome="ok"} -1'
      The contents of file "/tmp/metrics" should include 'check_certificates_expiration{domain="zero-days-left-ssl.com",outcome="ok"} 0'
      The contents of file "/tmp/metrics" should include 'check_certificates_expiration{domain="one-day-left-ssl.com",outcome="ok"} 1'
    End
  End

End