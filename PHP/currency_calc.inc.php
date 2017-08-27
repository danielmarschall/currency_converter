<?php

// PHP library for CurrencyLayer
// (C) 2017 ViaThinkSoft, Daniel Marschall
// Revision: 2017-03-25
//
// More information at https://currencylayer.com/documentation

# EXAMPLE
/*
$x = new CurCalc('cache.json', 'YOUR API KEY HERE', false);
if ($x->needs_download(1*60*60)) $x->download_exchange_rates(); // refresh data every hour
$val = $x->convert_cur(100, 'EUR', 'RUB');
echo "100 EUR are $val RUB.\n";
*/

# ---

class CurCalcException extends Exception {}
class CurrencyLayerException extends CurCalcException {}

class CurCalc {

	protected $jsonfile = null;
	protected $apikey = null;
	protected $use_https = null;
	function __construct($jsonfile, $apikey, $use_https=true) {
		$this->jsonfile = $jsonfile;
		$this->apikey = $apikey;
		$this->use_https = $use_https;
	}

	public function exchange_rates_age() {
		$this->check_json_file_exists();

		// return time() - filemtime($this->jsonfile);

		$cont = file_get_contents($this->jsonfile);
		$data = json_decode($cont, true);
		$this->check_data_ok($data);
		return time() - $data['timestamp'];
	}

	public function needs_download($max_age=-1) {
		if (!$this->check_json_file_exists(false)) {
			return true;
		} else if (!$this->check_data_ok(null, false)) {
			return true;
		} else if ($max_age == -1) {
			return false;
		} else {
			return $this->exchange_rates_age() > $max_age;
		}
	}

	private function check_json_file_exists($raise_exception=true) {
		if (!file_exists($this->jsonfile)) {
			if ($raise_exception) {
				throw new CurCalcException('JSON file '.$this->jsonfile.' not found. Please download it first.');
			} else {
				return false;
			}
		} else {
			return true;
		}
	}

	private function check_data_ok($data, $raise_exception=true) {
		if (is_null($data)) {
			$ret = $this->check_json_file_exists($raise_exception);
			if ((!$raise_exception) && (!$ret)) return $ret;
			$cont = file_get_contents($this->jsonfile);
			$data = json_decode($cont, true);
		}

		if ((!isset($data['success'])) || ($data['success'] !== true)) {
			if ($raise_exception) {
				if (isset($test_data['error'])) throw new CurrencyLayerException($test_data['error']['code'] . ' : ' . $test_data['error']['info']);
				throw new CurCalcException('JSON file '.$this->jsonfile.' does not contain valid request data. Please download it again.');
			} else {
				return false;
			}
		}

		return true;
	}

	public function download_exchange_rates() {
		// 1. Download
		$protocol = $this->use_https ? 'https' : 'http';
		$cont = file_get_contents($protocol.'://www.apilayer.net/api/live?access_key='.$this->apikey);
		if (!$cont) throw new CurCalcException('Failed to download from CurrencyLayer.');

		// 2. Test result
		$test_data = json_decode($cont, true);
		$this->check_data_ok($test_data);

		// 3. Save
		if (!file_put_contents($this->jsonfile, $cont)) throw new CurCalcException('Saving to '.$this->jsonfile.' failed.');

		// 4. OK
		$this->cache_exchange_rates_ary = null;
		return 0;
	}

	private $cache_exchange_rates_ary = null;
	private function get_exchange_rates_ary() {
		if (!is_null($this->cache_exchange_rates_ary)) return $this->cache_exchange_rates_ary;

		$this->check_json_file_exists();
		$data = json_decode(file_get_contents($this->jsonfile), true);
		$this->check_data_ok($data);

		$exchange_rates_ary = array();
		$quotes = $data['quotes'];
		foreach ($quotes as $n => $v) {
			$exchange_rates_ary[substr($n, 3, 3)] = $v; // key: USDxxx=12.345
		}
		unset($quotes);

		$this->cache_exchange_rates_ary = $exchange_rates_ary;
		return $exchange_rates_ary;
	}

	public function get_supported_currencies() {
		return array_keys($this->get_exchange_rates_ary());
	}

	public function convert_cur($value, $from_cur, $to_cur) {
		$exchange_rates_ary = $this->get_exchange_rates_ary();

		$from_cur = strtoupper(trim($from_cur));
		$to_cur = strtoupper(trim($to_cur));

		if (!isset($exchange_rates_ary[$from_cur])) throw new CurCalcException('Source curreny $from_cur not found in exchange data.');
		if (!isset($exchange_rates_ary[$to_cur])) throw new CurCalcException('Destination curreny $to_cur not found in exchange data.');

		return $value * $exchange_rates_ary[$to_cur]/$exchange_rates_ary[$from_cur];
	}

}
