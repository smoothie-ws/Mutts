package mutts.net;

import haxe.Json;
import s.Timer;
import s.net.Http;
import mutts.net.Types;

using StringTools;

class BackendApi {
	public var accessToken(default, null):String;
	public var refreshToken(default, null):String;
	public var tokenType(default, null):String = "Bearer";
	public var lastError(default, null):String;

	final origin:String;
	final failed:String->Void;

	public function new(origin:String, failed:String->Void) {
		this.origin = origin;
		this.failed = failed;
	}

	public function setTokens(tokens:AuthTokens):Void {
		accessToken = tokens.access_token;
		refreshToken = tokens.refresh_token;
		tokenType = tokens.token_type ?? "Bearer";
	}

	public function clearTokens():Void {
		accessToken = null;
		refreshToken = null;
		tokenType = "Bearer";
	}

	public function hasToken():Bool
		return accessToken != null && accessToken != "";

	public function refreshTokens(reportError:Bool = true):Bool {
		if (refreshToken == null || refreshToken == "") {
			lastError = "Refresh token is missing.";
			if (reportError)
				failed(lastError);
			return false;
		}

		final path = "/auth/refresh?refresh_token=" + refreshToken.urlEncode();
		final tokens:AuthTokens = postEmpty(path, reportError);
		if (tokens == null || tokens.access_token == null || tokens.access_token == "")
			return false;

		setTokens(tokens);
		return true;
	}

	public function tokenPath(path:String):String
		return path + (path.indexOf("?") == -1 ? "?" : "&") + "access_token=" + accessToken.urlEncode();

	public function encodedToken():String
		return accessToken.urlEncode();

	public function get<T>(path:String, authenticated:Bool = false, reportError:Bool = true):Null<T>
		return decode(Http.request(origin, {
			path: path,
			headers: authenticated ? authHeaders() : []
		}), reportError);

	public function postEmpty<T>(path:String, reportError:Bool = true):Null<T>
		return decode(Http.request(origin, {
			path: path,
			method: Post
		}), reportError);

	public function postForm<T>(path:String, params:Map<String, String>, reportError:Bool = true):Null<T>
		return decode(Http.request(origin, {
			path: path,
			method: Post,
			params: params
		}), reportError);

	public function postJson<T>(path:String, data:Dynamic, reportError:Bool = true):Null<T> {
		final headers:Map<s.net.http.HttpHeader, String> = [];
		headers.set("Content-Type", "application/json");
		return decode(Http.request(origin, {
			path: path,
			method: Post,
			headers: headers,
			data: Json.stringify(data)
		}), reportError);
	}

	public function getAsync<T>(path:String, authenticated:Bool, done:Null<T>->Void, ?shouldReportError:Void->Bool, ?error:String->Void):Void {
		async(() -> get(path, authenticated, false), done, shouldReportError, error);
	}

	public function postEmptyAsync<T>(path:String, done:Null<T>->Void, ?shouldReportError:Void->Bool, ?error:String->Void):Void {
		async(() -> postEmpty(path, false), done, shouldReportError, error);
	}

	function async<T>(request:Void->Null<T>, done:Null<T>->Void, ?shouldReportError:Void->Bool, ?error:String->Void):Void {
		Timer.set(() -> {
			final result = request();
			if (result == null && lastError != null) {
				if (error != null)
					error(lastError);
				else if (shouldReportError == null || shouldReportError())
					failed(lastError);
			}
			done(result);
		}, 0.01);
	}

	function decode<T>(response:s.net.HttpResponse, reportError:Bool = true):Null<T> {
		lastError = null;
		if (response == null)
			return fail("Backend did not return a response.", reportError);

		final status:Int = response.status;
		if (response.error != null || status < 200 || status >= 300)
			return fail(formatError(response), reportError);

		final body = response.data ?? response.bytes?.toString();
		if (body == null || body == "")
			return cast {};

		try {
			return Json.parse(body);
		} catch (e:Dynamic) {
			return fail("Backend returned invalid JSON: " + Std.string(e), reportError);
		}
	}

	function fail<T>(message:String, report:Bool):Null<T> {
		lastError = message;
		if (report)
			failed(message);
		return null;
	}

	function authHeaders():Map<s.net.http.HttpHeader, String> {
		final headers:Map<s.net.http.HttpHeader, String> = [];
		headers.set("Authorization", (tokenType == null || tokenType == "" ? "Bearer" : tokenType) + " " + accessToken);
		return headers;
	}

	function formatError(response:s.net.HttpResponse):String {
		final body = response.data ?? response.bytes?.toString();
		final parsed = formatErrorBody(body);
		return parsed ?? response.error ?? 'HTTP ${response.status}: ${response.statusText}';
	}

	function formatErrorBody(body:String):Null<String> {
		if (body != null && body != "")
			try {
				final parsed:Dynamic = Json.parse(body);
				final detail:Dynamic = parsed.detail;
				if (Std.isOfType(detail, String))
					return detail;
				if (Std.isOfType(detail, Array)) {
					final items:Array<Dynamic> = cast detail;
					if (items.length > 0 && items[0].msg != null)
						return Std.string(items[0].msg);
				}
				if (parsed.message != null)
					return Std.string(parsed.message);
				if (parsed.error != null)
					return Std.string(parsed.error);
			} catch (_:Dynamic) {}
		return null;
	}
}
