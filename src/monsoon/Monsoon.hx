package monsoon;

import haxe.DynamicAccess;
import tink.http.Container;
import tink.http.containers.*;
import tink.http.Request;
import tink.http.Response;
import tink.http.Handler;
import tink.http.Method;
import monsoon.Request;
import monsoon.Response;
import monsoon.Layer;
import path2ereg.Path2EReg;

using Lambda;
using tink.CoreApi;

@:forward
abstract Monsoon(List<Layer>) from List<Layer> {
	
	public inline function new()
		this = new List();
		
	public inline function add(layer: Layer): Monsoon {
		this.add(layer);
		return this;
	}
		
	public inline function get(?path: String, callback: Layer)
		return route(GET, path, callback);
	
	public inline function post(?path: String, callback: Layer)
		return route(POST, path, callback);
	
	public function route(?method: Method, ?path: String, callback: Layer, end = true)
		return add(function(req, res, next) {
			return 
				if (path != null) {
					var matcher = Path2EReg.toEReg(path, {end: end});
					if (!matcher.ereg.match(req.path)) {
						next();
					} else {
						var params: DynamicAccess<String> = {};
						for (i in 0 ... matcher.keys.length)
							params.set(matcher.keys[i].name, matcher.ereg.matched(i+1));
						req.params = cast params;
						req.path = end ? req.header.uri.path : matcher.ereg.matchedRight();
						callback(req, res, next);
					}
				} else {
					req.params = null;
					req.path = req.path == null ? req.header.uri.path : req.path;
					callback(req, res, next);
				}
		});
	
	public inline function use(?path: String, callback: Layer)
		return route(path, callback, false);
		
	public function serve(req: IncomingRequest) {
		return 
			try toHandler().process(req)
			catch (e: Dynamic) {
				var res = new Response();
				res.error('Unexpected exception: $e');
				res.future;
			}
	}
	
	public function layer(req, res, last) {
		var iter = this.iterator();
		function next()
			if (iter.hasNext())
				iter.next()(req, res, next)
			else
				last();
		next();
	}
	
	@:to
	public inline function toLayer(): Layer
		return layer;
		
	@:to
	public inline function toHandler(): Handler
		return toLayer();
	
	/*@:from
	public inline static function fromMap(map: Map<String, Layer>) {
		for (path in map.keys())
			route(path, map.get(key));
	}*/
	
	// todo: add options (watch, notfound, etc)
	public inline function listen(port: Int = 80): Future<ContainerResult>
		return (
			#if embed
				new TcpContainer(port)
			#elseif php
				PhpContainer.inst
			#elseif neko
				ModnekoContainer.inst
			#elseif nodejs
				new NodeContainer(port)
			#else
				#error
			#end
		).run(serve);

}