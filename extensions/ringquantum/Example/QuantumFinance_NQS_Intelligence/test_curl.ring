load "libcurl.ring"
curl = curl_easy_init()
curl_easy_setopt(curl, CURLOPT_URL, "https://query2.finance.yahoo.com/v8/finance/chart/AAPL?interval=1d&range=1mo")
curl_easy_setopt(curl, CURLOPT_USERAGENT, "Mozilla/5.0")
curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0)
curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0)
cContent = curl_easy_perform_silent(curl)
see "Length: " + len(cContent) + nl
see left(cContent, 100) + nl
curl_easy_cleanup(curl)
