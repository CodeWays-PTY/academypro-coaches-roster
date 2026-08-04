var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// node_modules/hono/dist/compose.js
var compose = /* @__PURE__ */ __name((middleware, onError, onNotFound) => {
  return (context, next) => {
    let index = -1;
    return dispatch(0);
    async function dispatch(i) {
      if (i <= index) {
        throw new Error("next() called multiple times");
      }
      index = i;
      let res;
      let isError = false;
      let handler;
      if (middleware[i]) {
        handler = middleware[i][0][0];
        context.req.routeIndex = i;
      } else {
        handler = i === middleware.length && next || void 0;
      }
      if (handler) {
        try {
          res = await handler(context, () => dispatch(i + 1));
        } catch (err) {
          if (err instanceof Error && onError) {
            context.error = err;
            res = await onError(err, context);
            isError = true;
          } else {
            throw err;
          }
        }
      } else {
        if (context.finalized === false && onNotFound) {
          res = await onNotFound(context);
        }
      }
      if (res && (context.finalized === false || isError)) {
        context.res = res;
      }
      return context;
    }
    __name(dispatch, "dispatch");
  };
}, "compose");

// node_modules/hono/dist/request/constants.js
var GET_MATCH_RESULT = /* @__PURE__ */ Symbol();

// node_modules/hono/dist/utils/buffer.js
var bufferToFormData = /* @__PURE__ */ __name((arrayBuffer, contentType) => {
  const response = new Response(arrayBuffer, {
    headers: {
      // Normalize the media type (case-insensitive) while keeping parameters like the boundary
      "Content-Type": contentType.replace(/^[^;]+/, (mediaType) => mediaType.toLowerCase())
    }
  });
  return response.formData();
}, "bufferToFormData");

// node_modules/hono/dist/utils/body.js
var isRawRequest = /* @__PURE__ */ __name((request) => "headers" in request, "isRawRequest");
var parseBody = /* @__PURE__ */ __name(async (request, options = /* @__PURE__ */ Object.create(null)) => {
  const { all = false, dot = false } = options;
  const headers = isRawRequest(request) ? request.headers : request.raw.headers;
  const contentType = headers.get("Content-Type");
  const mediaType = contentType?.split(";")[0].trim().toLowerCase();
  if (mediaType === "multipart/form-data" || mediaType === "application/x-www-form-urlencoded") {
    return parseFormData(request, { all, dot });
  }
  return {};
}, "parseBody");
async function parseFormData(request, options) {
  const headers = isRawRequest(request) ? request.headers : request.raw.headers;
  const arrayBuffer = await request.arrayBuffer();
  const formDataPromise = bufferToFormData(arrayBuffer, headers.get("Content-Type") || "");
  if (!isRawRequest(request)) {
    request.bodyCache.formData = formDataPromise;
  }
  const formData = await formDataPromise;
  if (formData) {
    return convertFormDataToBodyData(formData, options);
  }
  return {};
}
__name(parseFormData, "parseFormData");
function convertFormDataToBodyData(formData, options) {
  const form = /* @__PURE__ */ Object.create(null);
  formData.forEach((value, key) => {
    const shouldParseAllValues = options.all || key.endsWith("[]");
    if (!shouldParseAllValues) {
      form[key] = value;
    } else {
      handleParsingAllValues(form, key, value);
    }
  });
  if (options.dot) {
    Object.entries(form).forEach(([key, value]) => {
      const shouldParseDotValues = key.includes(".");
      if (shouldParseDotValues) {
        handleParsingNestedValues(form, key, value);
        delete form[key];
      }
    });
  }
  return form;
}
__name(convertFormDataToBodyData, "convertFormDataToBodyData");
var handleParsingAllValues = /* @__PURE__ */ __name((form, key, value) => {
  if (form[key] !== void 0) {
    if (Array.isArray(form[key])) {
      ;
      form[key].push(value);
    } else {
      form[key] = [form[key], value];
    }
  } else {
    if (!key.endsWith("[]")) {
      form[key] = value;
    } else {
      form[key] = [value];
    }
  }
}, "handleParsingAllValues");
var handleParsingNestedValues = /* @__PURE__ */ __name((form, key, value) => {
  if (/(?:^|\.)__proto__\./.test(key)) {
    return;
  }
  let nestedForm = form;
  const keys = key.split(".");
  keys.forEach((key2, index) => {
    if (index === keys.length - 1) {
      nestedForm[key2] = value;
    } else {
      if (!nestedForm[key2] || typeof nestedForm[key2] !== "object" || Array.isArray(nestedForm[key2]) || nestedForm[key2] instanceof File) {
        nestedForm[key2] = /* @__PURE__ */ Object.create(null);
      }
      nestedForm = nestedForm[key2];
    }
  });
}, "handleParsingNestedValues");

// node_modules/hono/dist/utils/url.js
var splitPath = /* @__PURE__ */ __name((path) => {
  const paths = path.split("/");
  if (paths[0] === "") {
    paths.shift();
  }
  return paths;
}, "splitPath");
var splitRoutingPath = /* @__PURE__ */ __name((routePath) => {
  const { groups, path } = extractGroupsFromPath(routePath);
  const paths = splitPath(path);
  return replaceGroupMarks(paths, groups);
}, "splitRoutingPath");
var extractGroupsFromPath = /* @__PURE__ */ __name((path) => {
  const groups = [];
  path = path.replace(/\{[^}]+\}/g, (match2, index) => {
    const mark = `@${index}`;
    groups.push([mark, match2]);
    return mark;
  });
  return { groups, path };
}, "extractGroupsFromPath");
var replaceGroupMarks = /* @__PURE__ */ __name((paths, groups) => {
  for (let i = groups.length - 1; i >= 0; i--) {
    const [mark] = groups[i];
    for (let j = paths.length - 1; j >= 0; j--) {
      if (paths[j].includes(mark)) {
        paths[j] = paths[j].replace(mark, groups[i][1]);
        break;
      }
    }
  }
  return paths;
}, "replaceGroupMarks");
var patternCache = {};
var getPattern = /* @__PURE__ */ __name((label, next) => {
  if (label === "*") {
    return "*";
  }
  const match2 = label.match(/^\:([^\{\}]+)(?:\{(.+)\})?$/);
  if (match2) {
    const cacheKey = `${label}#${next}`;
    if (!patternCache[cacheKey]) {
      if (match2[2]) {
        patternCache[cacheKey] = next && next[0] !== ":" && next[0] !== "*" ? [cacheKey, match2[1], new RegExp(`^${match2[2]}(?=/${next})`)] : [label, match2[1], new RegExp(`^${match2[2]}$`)];
      } else {
        patternCache[cacheKey] = [label, match2[1], true];
      }
    }
    return patternCache[cacheKey];
  }
  return null;
}, "getPattern");
var tryDecode = /* @__PURE__ */ __name((str, decoder) => {
  try {
    return decoder(str);
  } catch {
    return str.replace(/(?:%[0-9A-Fa-f]{2})+/g, (match2) => {
      try {
        return decoder(match2);
      } catch {
        return match2;
      }
    });
  }
}, "tryDecode");
var tryDecodeURI = /* @__PURE__ */ __name((str) => tryDecode(str, decodeURI), "tryDecodeURI");
var getPath = /* @__PURE__ */ __name((request) => {
  const url = request.url;
  const start = url.indexOf("/", url.indexOf(":") + 4);
  let i = start;
  for (; i < url.length; i++) {
    const charCode = url.charCodeAt(i);
    if (charCode === 37) {
      const queryIndex = url.indexOf("?", i);
      const hashIndex = url.indexOf("#", i);
      const end = queryIndex === -1 ? hashIndex === -1 ? void 0 : hashIndex : hashIndex === -1 ? queryIndex : Math.min(queryIndex, hashIndex);
      const path = url.slice(start, end);
      return tryDecodeURI(path.includes("%25") ? path.replace(/%25/g, "%2525") : path);
    } else if (charCode === 63 || charCode === 35) {
      break;
    }
  }
  return url.slice(start, i);
}, "getPath");
var getPathNoStrict = /* @__PURE__ */ __name((request) => {
  const result = getPath(request);
  return result.length > 1 && result.at(-1) === "/" ? result.slice(0, -1) : result;
}, "getPathNoStrict");
var mergePath = /* @__PURE__ */ __name((base, sub, ...rest) => {
  if (rest.length) {
    sub = mergePath(sub, ...rest);
  }
  return `${base?.[0] === "/" ? "" : "/"}${base}${sub === "/" ? "" : `${base?.at(-1) === "/" ? "" : "/"}${sub?.[0] === "/" ? sub.slice(1) : sub}`}`;
}, "mergePath");
var checkOptionalParameter = /* @__PURE__ */ __name((path) => {
  if (path.charCodeAt(path.length - 1) !== 63 || !path.includes(":")) {
    return null;
  }
  const segments = path.split("/");
  const results = [];
  let basePath = "";
  segments.forEach((segment) => {
    if (segment !== "" && !/\:/.test(segment)) {
      basePath += "/" + segment;
    } else if (/\:/.test(segment)) {
      if (/\?/.test(segment)) {
        if (results.length === 0 && basePath === "") {
          results.push("/");
        } else {
          results.push(basePath);
        }
        const optionalSegment = segment.replace("?", "");
        basePath += "/" + optionalSegment;
        results.push(basePath);
      } else {
        basePath += "/" + segment;
      }
    }
  });
  return results.filter((v, i, a) => a.indexOf(v) === i);
}, "checkOptionalParameter");
var _decodeURI = /* @__PURE__ */ __name((value) => {
  if (!/[%+]/.test(value)) {
    return value;
  }
  if (value.indexOf("+") !== -1) {
    value = value.replace(/\+/g, " ");
  }
  return value.indexOf("%") !== -1 ? tryDecode(value, decodeURIComponent_) : value;
}, "_decodeURI");
var _getQueryParam = /* @__PURE__ */ __name((url, key, multiple) => {
  let encoded;
  if (!multiple && key && !/[%+]/.test(key)) {
    let keyIndex2 = url.indexOf("?", 8);
    if (keyIndex2 === -1) {
      return void 0;
    }
    if (!url.startsWith(key, keyIndex2 + 1)) {
      keyIndex2 = url.indexOf(`&${key}`, keyIndex2 + 1);
    }
    while (keyIndex2 !== -1) {
      const trailingKeyCode = url.charCodeAt(keyIndex2 + key.length + 1);
      if (trailingKeyCode === 61) {
        const valueIndex = keyIndex2 + key.length + 2;
        const endIndex = url.indexOf("&", valueIndex);
        return _decodeURI(url.slice(valueIndex, endIndex === -1 ? void 0 : endIndex));
      } else if (trailingKeyCode == 38 || isNaN(trailingKeyCode)) {
        return "";
      }
      keyIndex2 = url.indexOf(`&${key}`, keyIndex2 + 1);
    }
    encoded = /[%+]/.test(url);
    if (!encoded) {
      return void 0;
    }
  }
  const results = {};
  encoded ??= /[%+]/.test(url);
  let keyIndex = url.indexOf("?", 8);
  while (keyIndex !== -1) {
    const nextKeyIndex = url.indexOf("&", keyIndex + 1);
    let valueIndex = url.indexOf("=", keyIndex);
    if (valueIndex > nextKeyIndex && nextKeyIndex !== -1) {
      valueIndex = -1;
    }
    let name = url.slice(
      keyIndex + 1,
      valueIndex === -1 ? nextKeyIndex === -1 ? void 0 : nextKeyIndex : valueIndex
    );
    if (encoded) {
      name = _decodeURI(name);
    }
    keyIndex = nextKeyIndex;
    if (name === "") {
      continue;
    }
    let value;
    if (valueIndex === -1) {
      value = "";
    } else {
      value = url.slice(valueIndex + 1, nextKeyIndex === -1 ? void 0 : nextKeyIndex);
      if (encoded) {
        value = _decodeURI(value);
      }
    }
    if (multiple) {
      if (!(results[name] && Array.isArray(results[name]))) {
        results[name] = [];
      }
      ;
      results[name].push(value);
    } else {
      results[name] ??= value;
    }
  }
  return key ? results[key] : results;
}, "_getQueryParam");
var getQueryParam = _getQueryParam;
var getQueryParams = /* @__PURE__ */ __name((url, key) => {
  return _getQueryParam(url, key, true);
}, "getQueryParams");
var decodeURIComponent_ = decodeURIComponent;

// node_modules/hono/dist/request.js
var tryDecodeURIComponent = /* @__PURE__ */ __name((str) => tryDecode(str, decodeURIComponent_), "tryDecodeURIComponent");
var HonoRequest = class {
  static {
    __name(this, "HonoRequest");
  }
  /**
   * `.raw` can get the raw Request object.
   *
   * @see {@link https://hono.dev/docs/api/request#raw}
   *
   * @example
   * ```ts
   * // For Cloudflare Workers
   * app.post('/', async (c) => {
   *   const metadata = c.req.raw.cf?.hostMetadata?
   *   ...
   * })
   * ```
   */
  raw;
  #validatedData;
  // Short name of validatedData
  #matchResult;
  routeIndex = 0;
  /**
   * `.path` can get the pathname of the request.
   *
   * @see {@link https://hono.dev/docs/api/request#path}
   *
   * @example
   * ```ts
   * app.get('/about/me', (c) => {
   *   const pathname = c.req.path // `/about/me`
   * })
   * ```
   */
  path;
  bodyCache = {};
  constructor(request, path = "/", matchResult = [[]]) {
    this.raw = request;
    this.path = path;
    this.#matchResult = matchResult;
    this.#validatedData = {};
  }
  param(key) {
    return key ? this.#getDecodedParam(key) : this.#getAllDecodedParams();
  }
  #getDecodedParam(key) {
    const paramKey = this.#matchResult[0][this.routeIndex][1][key];
    const param = this.#getParamValue(paramKey);
    return param && /\%/.test(param) ? tryDecodeURIComponent(param) : param;
  }
  #getAllDecodedParams() {
    const decoded = {};
    const keys = Object.keys(this.#matchResult[0][this.routeIndex][1]);
    for (const key of keys) {
      const value = this.#getParamValue(this.#matchResult[0][this.routeIndex][1][key]);
      if (value !== void 0) {
        decoded[key] = /\%/.test(value) ? tryDecodeURIComponent(value) : value;
      }
    }
    return decoded;
  }
  #getParamValue(paramKey) {
    return this.#matchResult[1] ? this.#matchResult[1][paramKey] : paramKey;
  }
  query(key) {
    return getQueryParam(this.url, key);
  }
  queries(key) {
    return getQueryParams(this.url, key);
  }
  header(name) {
    if (name) {
      return this.raw.headers.get(name) ?? void 0;
    }
    const headerData = {};
    this.raw.headers.forEach((value, key) => {
      headerData[key] = value;
    });
    return headerData;
  }
  async parseBody(options) {
    return parseBody(this, options);
  }
  #cachedBody = /* @__PURE__ */ __name((key) => {
    const { bodyCache, raw: raw2 } = this;
    const cachedBody = bodyCache[key];
    if (cachedBody) {
      return cachedBody;
    }
    const anyCachedKey = Object.keys(bodyCache)[0];
    if (anyCachedKey) {
      return bodyCache[anyCachedKey].then((body) => {
        if (anyCachedKey === "json") {
          body = JSON.stringify(body);
        }
        return new Response(body)[key]();
      });
    }
    return bodyCache[key] = raw2[key]();
  }, "#cachedBody");
  /**
   * `.json()` can parse Request body of type `application/json`
   *
   * @see {@link https://hono.dev/docs/api/request#json}
   *
   * @example
   * ```ts
   * app.post('/entry', async (c) => {
   *   const body = await c.req.json()
   * })
   * ```
   */
  json() {
    return this.#cachedBody("text").then((text) => JSON.parse(text));
  }
  /**
   * `.text()` can parse Request body of type `text/plain`
   *
   * @see {@link https://hono.dev/docs/api/request#text}
   *
   * @example
   * ```ts
   * app.post('/entry', async (c) => {
   *   const body = await c.req.text()
   * })
   * ```
   */
  text() {
    return this.#cachedBody("text");
  }
  /**
   * `.arrayBuffer()` parse Request body as an `ArrayBuffer`
   *
   * @see {@link https://hono.dev/docs/api/request#arraybuffer}
   *
   * @example
   * ```ts
   * app.post('/entry', async (c) => {
   *   const body = await c.req.arrayBuffer()
   * })
   * ```
   */
  arrayBuffer() {
    return this.#cachedBody("arrayBuffer");
  }
  /**
   * `.bytes()` parses the request body as a `Uint8Array`.
   *
   * @see {@link https://hono.dev/docs/api/request#bytes}
   *
   * @example
   * ```ts
   * app.post('/entry', async (c) => {
   *   const body = await c.req.bytes()
   * })
   * ```
   */
  bytes() {
    return this.#cachedBody("arrayBuffer").then((buffer) => new Uint8Array(buffer));
  }
  /**
   * Parses the request body as a `Blob`.
   * @example
   * ```ts
   * app.post('/entry', async (c) => {
   *   const body = await c.req.blob();
   * });
   * ```
   * @see https://hono.dev/docs/api/request#blob
   */
  blob() {
    return this.#cachedBody("blob");
  }
  /**
   * Parses the request body as `FormData`.
   * @example
   * ```ts
   * app.post('/entry', async (c) => {
   *   const body = await c.req.formData();
   * });
   * ```
   * @see https://hono.dev/docs/api/request#formdata
   */
  formData() {
    return this.#cachedBody("formData");
  }
  /**
   * Adds validated data to the request.
   *
   * @param target - The target of the validation.
   * @param data - The validated data to add.
   */
  addValidatedData(target, data) {
    this.#validatedData[target] = data;
  }
  valid(target) {
    return this.#validatedData[target];
  }
  /**
   * `.url()` can get the request url strings.
   *
   * @see {@link https://hono.dev/docs/api/request#url}
   *
   * @example
   * ```ts
   * app.get('/about/me', (c) => {
   *   const url = c.req.url // `http://localhost:8787/about/me`
   *   ...
   * })
   * ```
   */
  get url() {
    return this.raw.url;
  }
  /**
   * `.method()` can get the method name of the request.
   *
   * @see {@link https://hono.dev/docs/api/request#method}
   *
   * @example
   * ```ts
   * app.get('/about/me', (c) => {
   *   const method = c.req.method // `GET`
   * })
   * ```
   */
  get method() {
    return this.raw.method;
  }
  get [GET_MATCH_RESULT]() {
    return this.#matchResult;
  }
  /**
   * `.matchedRoutes()` can return a matched route in the handler
   *
   * @deprecated
   *
   * Use matchedRoutes helper defined in "hono/route" instead.
   *
   * @see {@link https://hono.dev/docs/api/request#matchedroutes}
   *
   * @example
   * ```ts
   * app.use('*', async function logger(c, next) {
   *   await next()
   *   c.req.matchedRoutes.forEach(({ handler, method, path }, i) => {
   *     const name = handler.name || (handler.length < 2 ? '[handler]' : '[middleware]')
   *     console.log(
   *       method,
   *       ' ',
   *       path,
   *       ' '.repeat(Math.max(10 - path.length, 0)),
   *       name,
   *       i === c.req.routeIndex ? '<- respond from here' : ''
   *     )
   *   })
   * })
   * ```
   */
  get matchedRoutes() {
    return this.#matchResult[0].map(([[, route]]) => route);
  }
  /**
   * `routePath()` can retrieve the path registered within the handler
   *
   * @deprecated
   *
   * Use routePath helper defined in "hono/route" instead.
   *
   * @see {@link https://hono.dev/docs/api/request#routepath}
   *
   * @example
   * ```ts
   * app.get('/posts/:id', (c) => {
   *   return c.json({ path: c.req.routePath })
   * })
   * ```
   */
  get routePath() {
    return this.#matchResult[0].map(([[, route]]) => route)[this.routeIndex].path;
  }
};

// node_modules/hono/dist/utils/html.js
var HtmlEscapedCallbackPhase = {
  Stringify: 1,
  BeforeStream: 2,
  Stream: 3
};
var raw = /* @__PURE__ */ __name((value, callbacks) => {
  const escapedString = new String(value);
  escapedString.isEscaped = true;
  escapedString.callbacks = callbacks;
  return escapedString;
}, "raw");
var resolveCallback = /* @__PURE__ */ __name(async (str, phase, preserveCallbacks, context, buffer) => {
  if (typeof str === "object" && !(str instanceof String)) {
    if (!(str instanceof Promise)) {
      str = str.toString();
    }
    if (str instanceof Promise) {
      str = await str;
    }
  }
  const callbacks = str.callbacks;
  if (!callbacks?.length) {
    return Promise.resolve(str);
  }
  if (buffer) {
    buffer[0] += str;
  } else {
    buffer = [str];
  }
  const resStr = Promise.all(callbacks.map((c) => c({ phase, buffer, context }))).then(
    (res) => Promise.all(
      res.filter(Boolean).map((str2) => resolveCallback(str2, phase, false, context, buffer))
    ).then(() => buffer[0])
  );
  if (preserveCallbacks) {
    return raw(await resStr, callbacks);
  } else {
    return resStr;
  }
}, "resolveCallback");

// node_modules/hono/dist/context.js
var TEXT_PLAIN = "text/plain; charset=UTF-8";
var setDefaultContentType = /* @__PURE__ */ __name((contentType, headers) => {
  return {
    "Content-Type": contentType,
    ...headers
  };
}, "setDefaultContentType");
var createResponseInstance = /* @__PURE__ */ __name((body, init) => new Response(body, init), "createResponseInstance");
var Context = class {
  static {
    __name(this, "Context");
  }
  #rawRequest;
  #req;
  /**
   * `.env` can get bindings (environment variables, secrets, KV namespaces, D1 database, R2 bucket etc.) in Cloudflare Workers.
   *
   * @see {@link https://hono.dev/docs/api/context#env}
   *
   * @example
   * ```ts
   * // Environment object for Cloudflare Workers
   * app.get('*', async c => {
   *   const counter = c.env.COUNTER
   * })
   * ```
   */
  env = {};
  #var;
  finalized = false;
  /**
   * `.error` can get the error object from the middleware if the Handler throws an error.
   *
   * @see {@link https://hono.dev/docs/api/context#error}
   *
   * @example
   * ```ts
   * app.use('*', async (c, next) => {
   *   await next()
   *   if (c.error) {
   *     // do something...
   *   }
   * })
   * ```
   */
  error;
  #status;
  #executionCtx;
  #res;
  #layout;
  #renderer;
  #notFoundHandler;
  #preparedHeaders;
  #matchResult;
  #path;
  /**
   * Creates an instance of the Context class.
   *
   * @param req - The Request object.
   * @param options - Optional configuration options for the context.
   */
  constructor(req, options) {
    this.#rawRequest = req;
    if (options) {
      this.#executionCtx = options.executionCtx;
      this.env = options.env;
      this.#notFoundHandler = options.notFoundHandler;
      this.#path = options.path;
      this.#matchResult = options.matchResult;
    }
  }
  /**
   * `.req` is the instance of {@link HonoRequest}.
   */
  get req() {
    this.#req ??= new HonoRequest(this.#rawRequest, this.#path, this.#matchResult);
    return this.#req;
  }
  /**
   * @see {@link https://hono.dev/docs/api/context#event}
   * The FetchEvent associated with the current request.
   *
   * @throws Will throw an error if the context does not have a FetchEvent.
   */
  get event() {
    if (this.#executionCtx && "respondWith" in this.#executionCtx) {
      return this.#executionCtx;
    } else {
      throw Error("This context has no FetchEvent");
    }
  }
  /**
   * @see {@link https://hono.dev/docs/api/context#executionctx}
   * The ExecutionContext associated with the current request.
   *
   * @throws Will throw an error if the context does not have an ExecutionContext.
   */
  get executionCtx() {
    if (this.#executionCtx) {
      return this.#executionCtx;
    } else {
      throw Error("This context has no ExecutionContext");
    }
  }
  /**
   * @see {@link https://hono.dev/docs/api/context#res}
   * The Response object for the current request.
   */
  get res() {
    return this.#res ||= createResponseInstance(null, {
      headers: this.#preparedHeaders ??= new Headers()
    });
  }
  /**
   * Sets the Response object for the current request.
   *
   * @param _res - The Response object to set.
   */
  set res(_res) {
    if (this.#res && _res) {
      _res = createResponseInstance(_res.body, _res);
      for (const [k, v] of this.#res.headers.entries()) {
        if (k === "content-type") {
          continue;
        }
        if (k === "set-cookie") {
          const cookies = this.#res.headers.getSetCookie();
          _res.headers.delete("set-cookie");
          for (const cookie of cookies) {
            _res.headers.append("set-cookie", cookie);
          }
        } else {
          _res.headers.set(k, v);
        }
      }
    }
    this.#res = _res;
    this.finalized = true;
  }
  /**
   * `.render()` can create a response within a layout.
   *
   * @see {@link https://hono.dev/docs/api/context#render-setrenderer}
   *
   * @example
   * ```ts
   * app.get('/', (c) => {
   *   return c.render('Hello!')
   * })
   * ```
   */
  render = /* @__PURE__ */ __name((...args) => {
    this.#renderer ??= (content) => this.html(content);
    return this.#renderer(...args);
  }, "render");
  /**
   * Sets the layout for the response.
   *
   * @param layout - The layout to set.
   * @returns The layout function.
   */
  setLayout = /* @__PURE__ */ __name((layout) => this.#layout = layout, "setLayout");
  /**
   * Gets the current layout for the response.
   *
   * @returns The current layout function.
   */
  getLayout = /* @__PURE__ */ __name(() => this.#layout, "getLayout");
  /**
   * `.setRenderer()` can set the layout in the custom middleware.
   *
   * @see {@link https://hono.dev/docs/api/context#render-setrenderer}
   *
   * @example
   * ```tsx
   * app.use('*', async (c, next) => {
   *   c.setRenderer((content) => {
   *     return c.html(
   *       <html>
   *         <body>
   *           <p>{content}</p>
   *         </body>
   *       </html>
   *     )
   *   })
   *   await next()
   * })
   * ```
   */
  setRenderer = /* @__PURE__ */ __name((renderer) => {
    this.#renderer = renderer;
  }, "setRenderer");
  /**
   * `.header()` can set headers.
   *
   * @see {@link https://hono.dev/docs/api/context#header}
   *
   * @example
   * ```ts
   * app.get('/welcome', (c) => {
   *   // Set headers
   *   c.header('X-Message', 'Hello!')
   *   c.header('Content-Type', 'text/plain')
   *
   *   return c.body('Thank you for coming')
   * })
   * ```
   */
  header = /* @__PURE__ */ __name((name, value, options) => {
    if (this.finalized) {
      this.#res = createResponseInstance(this.#res.body, this.#res);
    }
    const headers = this.#res ? this.#res.headers : this.#preparedHeaders ??= new Headers();
    if (value === void 0) {
      headers.delete(name);
    } else if (options?.append) {
      headers.append(name, value);
    } else {
      headers.set(name, value);
    }
  }, "header");
  status = /* @__PURE__ */ __name((status) => {
    this.#status = status;
  }, "status");
  /**
   * `.set()` can set the value specified by the key.
   *
   * @see {@link https://hono.dev/docs/api/context#set-get}
   *
   * @example
   * ```ts
   * app.use('*', async (c, next) => {
   *   c.set('message', 'Hono is hot!!')
   *   await next()
   * })
   * ```
   */
  set = /* @__PURE__ */ __name((key, value) => {
    this.#var ??= /* @__PURE__ */ new Map();
    this.#var.set(key, value);
  }, "set");
  /**
   * `.get()` can use the value specified by the key.
   *
   * @see {@link https://hono.dev/docs/api/context#set-get}
   *
   * @example
   * ```ts
   * app.get('/', (c) => {
   *   const message = c.get('message')
   *   return c.text(`The message is "${message}"`)
   * })
   * ```
   */
  get = /* @__PURE__ */ __name((key) => {
    return this.#var ? this.#var.get(key) : void 0;
  }, "get");
  /**
   * `.var` can access the value of a variable.
   *
   * @see {@link https://hono.dev/docs/api/context#var}
   *
   * @example
   * ```ts
   * const result = c.var.client.oneMethod()
   * ```
   */
  // c.var.propName is a read-only
  get var() {
    if (!this.#var) {
      return {};
    }
    return Object.fromEntries(this.#var);
  }
  #newResponse(data, arg, headers) {
    const responseHeaders = this.#res ? new Headers(this.#res.headers) : this.#preparedHeaders ?? new Headers();
    if (typeof arg === "object" && "headers" in arg) {
      const argHeaders = arg.headers instanceof Headers ? arg.headers : new Headers(arg.headers);
      for (const [key, value] of argHeaders) {
        if (key.toLowerCase() === "set-cookie") {
          responseHeaders.append(key, value);
        } else {
          responseHeaders.set(key, value);
        }
      }
    }
    if (headers) {
      for (const [k, v] of Object.entries(headers)) {
        if (typeof v === "string") {
          responseHeaders.set(k, v);
        } else {
          responseHeaders.delete(k);
          for (const v2 of v) {
            responseHeaders.append(k, v2);
          }
        }
      }
    }
    const status = typeof arg === "number" ? arg : arg?.status ?? this.#status;
    return createResponseInstance(data, { status, headers: responseHeaders });
  }
  newResponse = /* @__PURE__ */ __name((...args) => this.#newResponse(...args), "newResponse");
  /**
   * `.body()` can return the HTTP response.
   * You can set headers with `.header()` and set HTTP status code with `.status`.
   * This can also be set in `.text()`, `.json()` and so on.
   *
   * @see {@link https://hono.dev/docs/api/context#body}
   *
   * @example
   * ```ts
   * app.get('/welcome', (c) => {
   *   // Set headers
   *   c.header('X-Message', 'Hello!')
   *   c.header('Content-Type', 'text/plain')
   *   // Set HTTP status code
   *   c.status(201)
   *
   *   // Return the response body
   *   return c.body('Thank you for coming')
   * })
   * ```
   */
  body = /* @__PURE__ */ __name((data, arg, headers) => this.#newResponse(data, arg, headers), "body");
  /**
   * `.text()` can render text as `Content-Type:text/plain`.
   *
   * @see {@link https://hono.dev/docs/api/context#text}
   *
   * @example
   * ```ts
   * app.get('/say', (c) => {
   *   return c.text('Hello!')
   * })
   * ```
   */
  text = /* @__PURE__ */ __name((text, arg, headers) => {
    return !this.#preparedHeaders && !this.#status && !arg && !headers && !this.finalized ? new Response(text) : this.#newResponse(
      text,
      arg,
      setDefaultContentType(TEXT_PLAIN, headers)
    );
  }, "text");
  /**
   * `.json()` can render JSON as `Content-Type:application/json`.
   *
   * @see {@link https://hono.dev/docs/api/context#json}
   *
   * @example
   * ```ts
   * app.get('/api', (c) => {
   *   return c.json({ message: 'Hello!' })
   * })
   * ```
   */
  json = /* @__PURE__ */ __name((object, arg, headers) => {
    return this.#newResponse(
      JSON.stringify(object),
      arg,
      setDefaultContentType("application/json", headers)
    );
  }, "json");
  html = /* @__PURE__ */ __name((html, arg, headers) => {
    const res = /* @__PURE__ */ __name((html2) => this.#newResponse(html2, arg, setDefaultContentType("text/html; charset=UTF-8", headers)), "res");
    return typeof html === "object" ? resolveCallback(html, HtmlEscapedCallbackPhase.Stringify, false, {}).then(res) : res(html);
  }, "html");
  /**
   * `.redirect()` can Redirect, default status code is 302.
   *
   * @see {@link https://hono.dev/docs/api/context#redirect}
   *
   * @example
   * ```ts
   * app.get('/redirect', (c) => {
   *   return c.redirect('/')
   * })
   * app.get('/redirect-permanently', (c) => {
   *   return c.redirect('/', 301)
   * })
   * ```
   */
  redirect = /* @__PURE__ */ __name((location, status) => {
    const locationString = String(location);
    this.header(
      "Location",
      // Multibyes should be encoded
      // eslint-disable-next-line no-control-regex
      !/[^\x00-\xFF]/.test(locationString) ? locationString : encodeURI(locationString)
    );
    return this.newResponse(null, status ?? 302);
  }, "redirect");
  /**
   * `.notFound()` can return the Not Found Response.
   *
   * @see {@link https://hono.dev/docs/api/context#notfound}
   *
   * @example
   * ```ts
   * app.get('/notfound', (c) => {
   *   return c.notFound()
   * })
   * ```
   */
  notFound = /* @__PURE__ */ __name(() => {
    this.#notFoundHandler ??= () => createResponseInstance();
    return this.#notFoundHandler(this);
  }, "notFound");
};

// node_modules/hono/dist/router.js
var METHOD_NAME_ALL = "ALL";
var METHOD_NAME_ALL_LOWERCASE = "all";
var METHODS = ["get", "post", "put", "delete", "options", "patch"];
var MESSAGE_MATCHER_IS_ALREADY_BUILT = "Can not add a route since the matcher is already built.";
var UnsupportedPathError = class extends Error {
  static {
    __name(this, "UnsupportedPathError");
  }
};

// node_modules/hono/dist/utils/constants.js
var COMPOSED_HANDLER = "__COMPOSED_HANDLER";

// node_modules/hono/dist/hono-base.js
var notFoundHandler = /* @__PURE__ */ __name((c) => {
  return c.text("404 Not Found", 404);
}, "notFoundHandler");
var errorHandler = /* @__PURE__ */ __name((err, c) => {
  if ("getResponse" in err) {
    const res = err.getResponse();
    return c.newResponse(res.body, res);
  }
  console.error(err);
  return c.text("Internal Server Error", 500);
}, "errorHandler");
var Hono = class _Hono {
  static {
    __name(this, "_Hono");
  }
  get;
  post;
  put;
  delete;
  options;
  patch;
  all;
  on;
  use;
  /*
    This class is like an abstract class and does not have a router.
    To use it, inherit the class and implement router in the constructor.
  */
  router;
  getPath;
  // Cannot use `#` because it requires visibility at JavaScript runtime.
  _basePath = "/";
  #path = "/";
  routes = [];
  constructor(options = {}) {
    const allMethods = [...METHODS, METHOD_NAME_ALL_LOWERCASE];
    allMethods.forEach((method) => {
      this[method] = (args1, ...args) => {
        if (typeof args1 === "string") {
          this.#path = args1;
        } else {
          this.#addRoute(method, this.#path, args1);
        }
        args.forEach((handler) => {
          this.#addRoute(method, this.#path, handler);
        });
        return this;
      };
    });
    this.on = (method, path, ...handlers) => {
      for (const p of [path].flat()) {
        this.#path = p;
        for (const m of [method].flat()) {
          handlers.map((handler) => {
            this.#addRoute(m.toUpperCase(), this.#path, handler);
          });
        }
      }
      return this;
    };
    this.use = (arg1, ...handlers) => {
      if (typeof arg1 === "string") {
        this.#path = arg1;
      } else {
        this.#path = "*";
        handlers.unshift(arg1);
      }
      handlers.forEach((handler) => {
        this.#addRoute(METHOD_NAME_ALL, this.#path, handler);
      });
      return this;
    };
    const { strict, ...optionsWithoutStrict } = options;
    Object.assign(this, optionsWithoutStrict);
    this.getPath = strict ?? true ? options.getPath ?? getPath : getPathNoStrict;
  }
  #clone() {
    const clone = new _Hono({
      router: this.router,
      getPath: this.getPath
    });
    clone.errorHandler = this.errorHandler;
    clone.#notFoundHandler = this.#notFoundHandler;
    clone.routes = this.routes;
    return clone;
  }
  #notFoundHandler = notFoundHandler;
  // Cannot use `#` because it requires visibility at JavaScript runtime.
  errorHandler = errorHandler;
  /**
   * `.route()` allows grouping other Hono instance in routes.
   *
   * @see {@link https://hono.dev/docs/api/routing#grouping}
   *
   * @param {string} path - base Path
   * @param {Hono} app - other Hono instance
   * @returns {Hono} routed Hono instance
   *
   * @example
   * ```ts
   * const app = new Hono()
   * const app2 = new Hono()
   *
   * app2.get("/user", (c) => c.text("user"))
   * app.route("/api", app2) // GET /api/user
   * ```
   */
  route(path, app2) {
    const subApp = this.basePath(path);
    app2.routes.map((r) => {
      let handler;
      if (app2.errorHandler === errorHandler) {
        handler = r.handler;
      } else {
        handler = /* @__PURE__ */ __name(async (c, next) => (await compose([], app2.errorHandler)(c, () => r.handler(c, next))).res, "handler");
        handler[COMPOSED_HANDLER] = r.handler;
      }
      subApp.#addRoute(r.method, r.path, handler, r.basePath);
    });
    return this;
  }
  /**
   * `.basePath()` allows base paths to be specified.
   *
   * @see {@link https://hono.dev/docs/api/routing#base-path}
   *
   * @param {string} path - base Path
   * @returns {Hono} changed Hono instance
   *
   * @example
   * ```ts
   * const api = new Hono().basePath('/api')
   * ```
   */
  basePath(path) {
    const subApp = this.#clone();
    subApp._basePath = mergePath(this._basePath, path);
    return subApp;
  }
  /**
   * `.onError()` handles an error and returns a customized Response.
   *
   * @see {@link https://hono.dev/docs/api/hono#error-handling}
   *
   * @param {ErrorHandler} handler - request Handler for error
   * @returns {Hono} changed Hono instance
   *
   * @example
   * ```ts
   * app.onError((err, c) => {
   *   console.error(`${err}`)
   *   return c.text('Custom Error Message', 500)
   * })
   * ```
   */
  onError = /* @__PURE__ */ __name((handler) => {
    this.errorHandler = handler;
    return this;
  }, "onError");
  /**
   * `.notFound()` allows you to customize a Not Found Response.
   *
   * @see {@link https://hono.dev/docs/api/hono#not-found}
   *
   * @param {NotFoundHandler} handler - request handler for not-found
   * @returns {Hono} changed Hono instance
   *
   * @example
   * ```ts
   * app.notFound((c) => {
   *   return c.text('Custom 404 Message', 404)
   * })
   * ```
   */
  notFound = /* @__PURE__ */ __name((handler) => {
    this.#notFoundHandler = handler;
    return this;
  }, "notFound");
  /**
   * `.mount()` allows you to mount applications built with other frameworks into your Hono application.
   *
   * @see {@link https://hono.dev/docs/api/hono#mount}
   *
   * @param {string} path - base Path
   * @param {Function} applicationHandler - other Request Handler
   * @param {MountOptions} [options] - options of `.mount()`
   * @returns {Hono} mounted Hono instance
   *
   * @example
   * ```ts
   * import { Router as IttyRouter } from 'itty-router'
   * import { Hono } from 'hono'
   * // Create itty-router application
   * const ittyRouter = IttyRouter()
   * // GET /itty-router/hello
   * ittyRouter.get('/hello', () => new Response('Hello from itty-router'))
   *
   * const app = new Hono()
   * app.mount('/itty-router', ittyRouter.handle)
   * ```
   *
   * @example
   * ```ts
   * const app = new Hono()
   * // Send the request to another application without modification.
   * app.mount('/app', anotherApp, {
   *   replaceRequest: (req) => req,
   * })
   * ```
   */
  mount(path, applicationHandler, options) {
    let replaceRequest;
    let optionHandler;
    if (options) {
      if (typeof options === "function") {
        optionHandler = options;
      } else {
        optionHandler = options.optionHandler;
        if (options.replaceRequest === false) {
          replaceRequest = /* @__PURE__ */ __name((request) => request, "replaceRequest");
        } else {
          replaceRequest = options.replaceRequest;
        }
      }
    }
    const getOptions = optionHandler ? (c) => {
      const options2 = optionHandler(c);
      return Array.isArray(options2) ? options2 : [options2];
    } : (c) => {
      let executionContext = void 0;
      try {
        executionContext = c.executionCtx;
      } catch {
      }
      return [c.env, executionContext];
    };
    replaceRequest ||= (() => {
      const mergedPath = mergePath(this._basePath, path);
      const pathPrefixLength = mergedPath === "/" ? 0 : mergedPath.length;
      return (request) => {
        const url = new URL(request.url);
        url.pathname = this.getPath(request).slice(pathPrefixLength) || "/";
        return new Request(url, request);
      };
    })();
    const handler = /* @__PURE__ */ __name(async (c, next) => {
      const res = await applicationHandler(replaceRequest(c.req.raw), ...getOptions(c));
      if (res) {
        return res;
      }
      await next();
    }, "handler");
    this.#addRoute(METHOD_NAME_ALL, mergePath(path, "*"), handler);
    return this;
  }
  #addRoute(method, path, handler, baseRoutePath) {
    method = method.toUpperCase();
    path = mergePath(this._basePath, path);
    const r = {
      basePath: baseRoutePath !== void 0 ? mergePath(this._basePath, baseRoutePath) : this._basePath,
      path,
      method,
      handler
    };
    this.router.add(method, path, [handler, r]);
    this.routes.push(r);
  }
  #handleError(err, c) {
    if (err instanceof Error) {
      return this.errorHandler(err, c);
    }
    throw err;
  }
  #dispatch(request, executionCtx, env, method) {
    if (method === "HEAD") {
      return (async () => new Response(null, await this.#dispatch(request, executionCtx, env, "GET")))();
    }
    const path = this.getPath(request, { env });
    const matchResult = this.router.match(method, path);
    const c = new Context(request, {
      path,
      matchResult,
      env,
      executionCtx,
      notFoundHandler: this.#notFoundHandler
    });
    if (matchResult[0].length === 1) {
      let res;
      try {
        res = matchResult[0][0][0][0](c, async () => {
          c.res = await this.#notFoundHandler(c);
        });
      } catch (err) {
        return this.#handleError(err, c);
      }
      return res instanceof Promise ? res.then(
        (resolved) => resolved || (c.finalized ? c.res : this.#notFoundHandler(c))
      ).catch((err) => this.#handleError(err, c)) : res ?? this.#notFoundHandler(c);
    }
    const composed = compose(matchResult[0], this.errorHandler, this.#notFoundHandler);
    return (async () => {
      try {
        const context = await composed(c);
        if (!context.finalized) {
          throw new Error(
            "Context is not finalized. Did you forget to return a Response object or `await next()`?"
          );
        }
        return context.res;
      } catch (err) {
        return this.#handleError(err, c);
      }
    })();
  }
  /**
   * `.fetch()` will be entry point of your app.
   *
   * @see {@link https://hono.dev/docs/api/hono#fetch}
   *
   * @param {Request} request - request Object of request
   * @param {Env} Env - env Object
   * @param {ExecutionContext} - context of execution
   * @returns {Response | Promise<Response>} response of request
   *
   */
  fetch = /* @__PURE__ */ __name((request, ...rest) => {
    return this.#dispatch(request, rest[1], rest[0], request.method);
  }, "fetch");
  /**
   * `.request()` is a useful method for testing.
   * You can pass a URL or pathname to send a GET request.
   * app will return a Response object.
   * ```ts
   * test('GET /hello is ok', async () => {
   *   const res = await app.request('/hello')
   *   expect(res.status).toBe(200)
   * })
   * ```
   * @see https://hono.dev/docs/api/hono#request
   */
  request = /* @__PURE__ */ __name((input, requestInit, Env, executionCtx) => {
    if (input instanceof Request) {
      return this.fetch(requestInit ? new Request(input, requestInit) : input, Env, executionCtx);
    }
    input = input.toString();
    return this.fetch(
      new Request(
        /^https?:\/\//.test(input) ? input : `http://localhost${mergePath("/", input)}`,
        requestInit
      ),
      Env,
      executionCtx
    );
  }, "request");
  /**
   * `.fire()` automatically adds a global fetch event listener.
   * This can be useful for environments that adhere to the Service Worker API, such as non-ES module Cloudflare Workers.
   * @deprecated
   * Use `fire` from `hono/service-worker` instead.
   * ```ts
   * import { Hono } from 'hono'
   * import { fire } from 'hono/service-worker'
   *
   * const app = new Hono()
   * // ...
   * fire(app)
   * ```
   * @see https://hono.dev/docs/api/hono#fire
   * @see https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API
   * @see https://developers.cloudflare.com/workers/reference/migrate-to-module-workers/
   */
  fire = /* @__PURE__ */ __name(() => {
    addEventListener("fetch", (event) => {
      event.respondWith(this.#dispatch(event.request, event, void 0, event.request.method));
    });
  }, "fire");
};

// node_modules/hono/dist/router/reg-exp-router/matcher.js
var emptyParam = [];
function match(method, path) {
  const matchers = this.buildAllMatchers();
  const match2 = /* @__PURE__ */ __name(((method2, path2) => {
    const matcher = matchers[method2] || matchers[METHOD_NAME_ALL];
    const staticMatch = matcher[2][path2];
    if (staticMatch) {
      return staticMatch;
    }
    const match3 = path2.match(matcher[0]);
    if (!match3) {
      return [[], emptyParam];
    }
    const index = match3.indexOf("", 1);
    return [matcher[1][index], match3];
  }), "match2");
  this.match = match2;
  return match2(method, path);
}
__name(match, "match");

// node_modules/hono/dist/router/reg-exp-router/node.js
var LABEL_REG_EXP_STR = "[^/]+";
var ONLY_WILDCARD_REG_EXP_STR = ".*";
var TAIL_WILDCARD_REG_EXP_STR = "(?:|/.*)";
var PATH_ERROR = /* @__PURE__ */ Symbol();
var regExpMetaChars = new Set(".\\+*[^]$()");
function compareKey(a, b) {
  if (a.length === 1) {
    return b.length === 1 ? a < b ? -1 : 1 : -1;
  }
  if (b.length === 1) {
    return 1;
  }
  if (a === ONLY_WILDCARD_REG_EXP_STR || a === TAIL_WILDCARD_REG_EXP_STR) {
    return 1;
  } else if (b === ONLY_WILDCARD_REG_EXP_STR || b === TAIL_WILDCARD_REG_EXP_STR) {
    return -1;
  }
  if (a === LABEL_REG_EXP_STR) {
    return 1;
  } else if (b === LABEL_REG_EXP_STR) {
    return -1;
  }
  return a.length === b.length ? a < b ? -1 : 1 : b.length - a.length;
}
__name(compareKey, "compareKey");
var Node = class _Node {
  static {
    __name(this, "_Node");
  }
  #index;
  #varIndex;
  #children = /* @__PURE__ */ Object.create(null);
  insert(tokens, index, paramMap, context, pathErrorCheckOnly) {
    if (tokens.length === 0) {
      if (this.#index !== void 0) {
        throw PATH_ERROR;
      }
      if (pathErrorCheckOnly) {
        return;
      }
      this.#index = index;
      return;
    }
    const [token, ...restTokens] = tokens;
    const pattern = token === "*" ? restTokens.length === 0 ? ["", "", ONLY_WILDCARD_REG_EXP_STR] : ["", "", LABEL_REG_EXP_STR] : token === "/*" ? ["", "", TAIL_WILDCARD_REG_EXP_STR] : token.match(/^\:([^\{\}]+)(?:\{(.+)\})?$/);
    let node;
    if (pattern) {
      const name = pattern[1];
      let regexpStr = pattern[2] || LABEL_REG_EXP_STR;
      if (name && pattern[2]) {
        if (regexpStr === ".*") {
          throw PATH_ERROR;
        }
        regexpStr = regexpStr.replace(/^\((?!\?:)(?=[^)]+\)$)/, "(?:");
        if (/\((?!\?:)/.test(regexpStr)) {
          throw PATH_ERROR;
        }
      }
      node = this.#children[regexpStr];
      if (!node) {
        if (Object.keys(this.#children).some(
          (k) => k !== ONLY_WILDCARD_REG_EXP_STR && k !== TAIL_WILDCARD_REG_EXP_STR
        )) {
          throw PATH_ERROR;
        }
        if (pathErrorCheckOnly) {
          return;
        }
        node = this.#children[regexpStr] = new _Node();
        if (name !== "") {
          node.#varIndex = context.varIndex++;
        }
      }
      if (!pathErrorCheckOnly && name !== "") {
        paramMap.push([name, node.#varIndex]);
      }
    } else {
      node = this.#children[token];
      if (!node) {
        if (Object.keys(this.#children).some(
          (k) => k.length > 1 && k !== ONLY_WILDCARD_REG_EXP_STR && k !== TAIL_WILDCARD_REG_EXP_STR
        )) {
          throw PATH_ERROR;
        }
        if (pathErrorCheckOnly) {
          return;
        }
        node = this.#children[token] = new _Node();
      }
    }
    node.insert(restTokens, index, paramMap, context, pathErrorCheckOnly);
  }
  buildRegExpStr() {
    const childKeys = Object.keys(this.#children).sort(compareKey);
    const strList = childKeys.map((k) => {
      const c = this.#children[k];
      return (typeof c.#varIndex === "number" ? `(${k})@${c.#varIndex}` : regExpMetaChars.has(k) ? `\\${k}` : k) + c.buildRegExpStr();
    });
    if (typeof this.#index === "number") {
      strList.unshift(`#${this.#index}`);
    }
    if (strList.length === 0) {
      return "";
    }
    if (strList.length === 1) {
      return strList[0];
    }
    return "(?:" + strList.join("|") + ")";
  }
};

// node_modules/hono/dist/router/reg-exp-router/trie.js
var Trie = class {
  static {
    __name(this, "Trie");
  }
  #context = { varIndex: 0 };
  #root = new Node();
  insert(path, index, pathErrorCheckOnly) {
    const paramAssoc = [];
    const groups = [];
    for (let i = 0; ; ) {
      let replaced = false;
      path = path.replace(/\{[^}]+\}/g, (m) => {
        const mark = `@\\${i}`;
        groups[i] = [mark, m];
        i++;
        replaced = true;
        return mark;
      });
      if (!replaced) {
        break;
      }
    }
    const tokens = path.match(/(?::[^\/]+)|(?:\/\*$)|./g) || [];
    for (let i = groups.length - 1; i >= 0; i--) {
      const [mark] = groups[i];
      for (let j = tokens.length - 1; j >= 0; j--) {
        if (tokens[j].indexOf(mark) !== -1) {
          tokens[j] = tokens[j].replace(mark, groups[i][1]);
          break;
        }
      }
    }
    this.#root.insert(tokens, index, paramAssoc, this.#context, pathErrorCheckOnly);
    return paramAssoc;
  }
  buildRegExp() {
    let regexp = this.#root.buildRegExpStr();
    if (regexp === "") {
      return [/^$/, [], []];
    }
    let captureIndex = 0;
    const indexReplacementMap = [];
    const paramReplacementMap = [];
    regexp = regexp.replace(/#(\d+)|@(\d+)|\.\*\$/g, (_, handlerIndex, paramIndex) => {
      if (handlerIndex !== void 0) {
        indexReplacementMap[++captureIndex] = Number(handlerIndex);
        return "$()";
      }
      if (paramIndex !== void 0) {
        paramReplacementMap[Number(paramIndex)] = ++captureIndex;
        return "";
      }
      return "";
    });
    return [new RegExp(`^${regexp}`), indexReplacementMap, paramReplacementMap];
  }
};

// node_modules/hono/dist/router/reg-exp-router/router.js
var nullMatcher = [/^$/, [], /* @__PURE__ */ Object.create(null)];
var wildcardRegExpCache = /* @__PURE__ */ Object.create(null);
function buildWildcardRegExp(path) {
  return wildcardRegExpCache[path] ??= new RegExp(
    path === "*" ? "" : `^${path.replace(
      /\/\*$|([.\\+*[^\]$()])/g,
      (_, metaChar) => metaChar ? `\\${metaChar}` : "(?:|/.*)"
    )}$`
  );
}
__name(buildWildcardRegExp, "buildWildcardRegExp");
function clearWildcardRegExpCache() {
  wildcardRegExpCache = /* @__PURE__ */ Object.create(null);
}
__name(clearWildcardRegExpCache, "clearWildcardRegExpCache");
function buildMatcherFromPreprocessedRoutes(routes) {
  const trie = new Trie();
  const handlerData = [];
  if (routes.length === 0) {
    return nullMatcher;
  }
  const routesWithStaticPathFlag = routes.map(
    (route) => [!/\*|\/:/.test(route[0]), ...route]
  ).sort(
    ([isStaticA, pathA], [isStaticB, pathB]) => isStaticA ? 1 : isStaticB ? -1 : pathA.length - pathB.length
  );
  const staticMap = /* @__PURE__ */ Object.create(null);
  for (let i = 0, j = -1, len = routesWithStaticPathFlag.length; i < len; i++) {
    const [pathErrorCheckOnly, path, handlers] = routesWithStaticPathFlag[i];
    if (pathErrorCheckOnly) {
      staticMap[path] = [handlers.map(([h]) => [h, /* @__PURE__ */ Object.create(null)]), emptyParam];
    } else {
      j++;
    }
    let paramAssoc;
    try {
      paramAssoc = trie.insert(path, j, pathErrorCheckOnly);
    } catch (e) {
      throw e === PATH_ERROR ? new UnsupportedPathError(path) : e;
    }
    if (pathErrorCheckOnly) {
      continue;
    }
    handlerData[j] = handlers.map(([h, paramCount]) => {
      const paramIndexMap = /* @__PURE__ */ Object.create(null);
      paramCount -= 1;
      for (; paramCount >= 0; paramCount--) {
        const [key, value] = paramAssoc[paramCount];
        paramIndexMap[key] = value;
      }
      return [h, paramIndexMap];
    });
  }
  const [regexp, indexReplacementMap, paramReplacementMap] = trie.buildRegExp();
  for (let i = 0, len = handlerData.length; i < len; i++) {
    for (let j = 0, len2 = handlerData[i].length; j < len2; j++) {
      const map = handlerData[i][j]?.[1];
      if (!map) {
        continue;
      }
      const keys = Object.keys(map);
      for (let k = 0, len3 = keys.length; k < len3; k++) {
        map[keys[k]] = paramReplacementMap[map[keys[k]]];
      }
    }
  }
  const handlerMap = [];
  for (const i in indexReplacementMap) {
    handlerMap[i] = handlerData[indexReplacementMap[i]];
  }
  return [regexp, handlerMap, staticMap];
}
__name(buildMatcherFromPreprocessedRoutes, "buildMatcherFromPreprocessedRoutes");
function findMiddleware(middleware, path) {
  if (!middleware) {
    return void 0;
  }
  for (const k of Object.keys(middleware).sort((a, b) => b.length - a.length)) {
    if (buildWildcardRegExp(k).test(path)) {
      return [...middleware[k]];
    }
  }
  return void 0;
}
__name(findMiddleware, "findMiddleware");
var RegExpRouter = class {
  static {
    __name(this, "RegExpRouter");
  }
  name = "RegExpRouter";
  #middleware;
  #routes;
  constructor() {
    this.#middleware = { [METHOD_NAME_ALL]: /* @__PURE__ */ Object.create(null) };
    this.#routes = { [METHOD_NAME_ALL]: /* @__PURE__ */ Object.create(null) };
  }
  add(method, path, handler) {
    const middleware = this.#middleware;
    const routes = this.#routes;
    if (!middleware || !routes) {
      throw new Error(MESSAGE_MATCHER_IS_ALREADY_BUILT);
    }
    if (!middleware[method]) {
      ;
      [middleware, routes].forEach((handlerMap) => {
        handlerMap[method] = /* @__PURE__ */ Object.create(null);
        Object.keys(handlerMap[METHOD_NAME_ALL]).forEach((p) => {
          handlerMap[method][p] = [...handlerMap[METHOD_NAME_ALL][p]];
        });
      });
    }
    if (path === "/*") {
      path = "*";
    }
    const paramCount = (path.match(/\/:/g) || []).length;
    if (/\*$/.test(path)) {
      const re = buildWildcardRegExp(path);
      if (method === METHOD_NAME_ALL) {
        Object.keys(middleware).forEach((m) => {
          middleware[m][path] ||= findMiddleware(middleware[m], path) || findMiddleware(middleware[METHOD_NAME_ALL], path) || [];
        });
      } else {
        middleware[method][path] ||= findMiddleware(middleware[method], path) || findMiddleware(middleware[METHOD_NAME_ALL], path) || [];
      }
      Object.keys(middleware).forEach((m) => {
        if (method === METHOD_NAME_ALL || method === m) {
          Object.keys(middleware[m]).forEach((p) => {
            re.test(p) && middleware[m][p].push([handler, paramCount]);
          });
        }
      });
      Object.keys(routes).forEach((m) => {
        if (method === METHOD_NAME_ALL || method === m) {
          Object.keys(routes[m]).forEach(
            (p) => re.test(p) && routes[m][p].push([handler, paramCount])
          );
        }
      });
      return;
    }
    const paths = checkOptionalParameter(path) || [path];
    for (let i = 0, len = paths.length; i < len; i++) {
      const path2 = paths[i];
      Object.keys(routes).forEach((m) => {
        if (method === METHOD_NAME_ALL || method === m) {
          routes[m][path2] ||= [
            ...findMiddleware(middleware[m], path2) || findMiddleware(middleware[METHOD_NAME_ALL], path2) || []
          ];
          routes[m][path2].push([handler, paramCount - len + i + 1]);
        }
      });
    }
  }
  match = match;
  buildAllMatchers() {
    const matchers = /* @__PURE__ */ Object.create(null);
    Object.keys(this.#routes).concat(Object.keys(this.#middleware)).forEach((method) => {
      matchers[method] ||= this.#buildMatcher(method);
    });
    this.#middleware = this.#routes = void 0;
    clearWildcardRegExpCache();
    return matchers;
  }
  #buildMatcher(method) {
    const routes = [];
    let hasOwnRoute = method === METHOD_NAME_ALL;
    [this.#middleware, this.#routes].forEach((r) => {
      const ownRoute = r[method] ? Object.keys(r[method]).map((path) => [path, r[method][path]]) : [];
      if (ownRoute.length !== 0) {
        hasOwnRoute ||= true;
        routes.push(...ownRoute);
      } else if (method !== METHOD_NAME_ALL) {
        routes.push(
          ...Object.keys(r[METHOD_NAME_ALL]).map((path) => [path, r[METHOD_NAME_ALL][path]])
        );
      }
    });
    if (!hasOwnRoute) {
      return null;
    } else {
      return buildMatcherFromPreprocessedRoutes(routes);
    }
  }
};

// node_modules/hono/dist/router/smart-router/router.js
var SmartRouter = class {
  static {
    __name(this, "SmartRouter");
  }
  name = "SmartRouter";
  #routers = [];
  #routes = [];
  constructor(init) {
    this.#routers = init.routers;
  }
  add(method, path, handler) {
    if (!this.#routes) {
      throw new Error(MESSAGE_MATCHER_IS_ALREADY_BUILT);
    }
    this.#routes.push([method, path, handler]);
  }
  match(method, path) {
    if (!this.#routes) {
      throw new Error("Fatal error");
    }
    const routers = this.#routers;
    const routes = this.#routes;
    const len = routers.length;
    let i = 0;
    let res;
    for (; i < len; i++) {
      const router = routers[i];
      try {
        for (let i2 = 0, len2 = routes.length; i2 < len2; i2++) {
          router.add(...routes[i2]);
        }
        res = router.match(method, path);
      } catch (e) {
        if (e instanceof UnsupportedPathError) {
          continue;
        }
        throw e;
      }
      this.match = router.match.bind(router);
      this.#routers = [router];
      this.#routes = void 0;
      break;
    }
    if (i === len) {
      throw new Error("Fatal error");
    }
    this.name = `SmartRouter + ${this.activeRouter.name}`;
    return res;
  }
  get activeRouter() {
    if (this.#routes || this.#routers.length !== 1) {
      throw new Error("No active router has been determined yet.");
    }
    return this.#routers[0];
  }
};

// node_modules/hono/dist/router/trie-router/node.js
var emptyParams = /* @__PURE__ */ Object.create(null);
var hasChildren = /* @__PURE__ */ __name((children) => {
  for (const _ in children) {
    return true;
  }
  return false;
}, "hasChildren");
var Node2 = class _Node2 {
  static {
    __name(this, "_Node");
  }
  #methods;
  #children;
  #patterns;
  #order = 0;
  #params = emptyParams;
  constructor(method, handler, children) {
    this.#children = children || /* @__PURE__ */ Object.create(null);
    this.#methods = [];
    if (method && handler) {
      const m = /* @__PURE__ */ Object.create(null);
      m[method] = { handler, possibleKeys: [], score: 0 };
      this.#methods = [m];
    }
    this.#patterns = [];
  }
  insert(method, path, handler) {
    this.#order = ++this.#order;
    let curNode = this;
    const parts = splitRoutingPath(path);
    const possibleKeys = [];
    for (let i = 0, len = parts.length; i < len; i++) {
      const p = parts[i];
      const nextP = parts[i + 1];
      const pattern = getPattern(p, nextP);
      const key = Array.isArray(pattern) ? pattern[0] : p;
      if (key in curNode.#children) {
        curNode = curNode.#children[key];
        if (pattern) {
          possibleKeys.push(pattern[1]);
        }
        continue;
      }
      curNode.#children[key] = new _Node2();
      if (pattern) {
        curNode.#patterns.push(pattern);
        possibleKeys.push(pattern[1]);
      }
      curNode = curNode.#children[key];
    }
    curNode.#methods.push({
      [method]: {
        handler,
        possibleKeys: possibleKeys.filter((v, i, a) => a.indexOf(v) === i),
        score: this.#order
      }
    });
    return curNode;
  }
  #pushHandlerSets(handlerSets, node, method, nodeParams, params) {
    for (let i = 0, len = node.#methods.length; i < len; i++) {
      const m = node.#methods[i];
      const handlerSet = m[method] || m[METHOD_NAME_ALL];
      const processedSet = {};
      if (handlerSet !== void 0) {
        handlerSet.params = /* @__PURE__ */ Object.create(null);
        handlerSets.push(handlerSet);
        if (nodeParams !== emptyParams || params && params !== emptyParams) {
          for (let i2 = 0, len2 = handlerSet.possibleKeys.length; i2 < len2; i2++) {
            const key = handlerSet.possibleKeys[i2];
            const processed = processedSet[handlerSet.score];
            handlerSet.params[key] = params?.[key] && !processed ? params[key] : nodeParams[key] ?? params?.[key];
            processedSet[handlerSet.score] = true;
          }
        }
      }
    }
  }
  search(method, path) {
    const handlerSets = [];
    this.#params = emptyParams;
    const curNode = this;
    let curNodes = [curNode];
    const parts = splitPath(path);
    const curNodesQueue = [];
    const len = parts.length;
    let partOffsets = null;
    for (let i = 0; i < len; i++) {
      const part = parts[i];
      const isLast = i === len - 1;
      const tempNodes = [];
      for (let j = 0, len2 = curNodes.length; j < len2; j++) {
        const node = curNodes[j];
        const nextNode = node.#children[part];
        if (nextNode) {
          nextNode.#params = node.#params;
          if (isLast) {
            if (nextNode.#children["*"]) {
              this.#pushHandlerSets(handlerSets, nextNode.#children["*"], method, node.#params);
            }
            this.#pushHandlerSets(handlerSets, nextNode, method, node.#params);
          } else {
            tempNodes.push(nextNode);
          }
        }
        for (let k = 0, len3 = node.#patterns.length; k < len3; k++) {
          const pattern = node.#patterns[k];
          const params = node.#params === emptyParams ? {} : { ...node.#params };
          if (pattern === "*") {
            const astNode = node.#children["*"];
            if (astNode) {
              this.#pushHandlerSets(handlerSets, astNode, method, node.#params);
              astNode.#params = params;
              tempNodes.push(astNode);
            }
            continue;
          }
          const [key, name, matcher] = pattern;
          if (!part && !(matcher instanceof RegExp)) {
            continue;
          }
          const child = node.#children[key];
          if (matcher instanceof RegExp) {
            if (partOffsets === null) {
              partOffsets = new Array(len);
              let offset = path[0] === "/" ? 1 : 0;
              for (let p = 0; p < len; p++) {
                partOffsets[p] = offset;
                offset += parts[p].length + 1;
              }
            }
            const restPathString = path.substring(partOffsets[i]);
            const m = matcher.exec(restPathString);
            if (m) {
              params[name] = m[0];
              this.#pushHandlerSets(handlerSets, child, method, node.#params, params);
              if (m[0].length === restPathString.length && child.#children["*"]) {
                this.#pushHandlerSets(
                  handlerSets,
                  child.#children["*"],
                  method,
                  node.#params,
                  params
                );
              }
              if (hasChildren(child.#children)) {
                child.#params = params;
                const componentCount = m[0].match(/\//)?.length ?? 0;
                const targetCurNodes = curNodesQueue[componentCount] ||= [];
                targetCurNodes.push(child);
              }
              continue;
            }
          }
          if (matcher === true || matcher.test(part)) {
            params[name] = part;
            if (isLast) {
              this.#pushHandlerSets(handlerSets, child, method, params, node.#params);
              if (child.#children["*"]) {
                this.#pushHandlerSets(
                  handlerSets,
                  child.#children["*"],
                  method,
                  params,
                  node.#params
                );
              }
            } else {
              child.#params = params;
              tempNodes.push(child);
            }
          }
        }
      }
      const shifted = curNodesQueue.shift();
      curNodes = shifted ? tempNodes.concat(shifted) : tempNodes;
    }
    if (handlerSets.length > 1) {
      handlerSets.sort((a, b) => {
        return a.score - b.score;
      });
    }
    return [handlerSets.map(({ handler, params }) => [handler, params])];
  }
};

// node_modules/hono/dist/router/trie-router/router.js
var TrieRouter = class {
  static {
    __name(this, "TrieRouter");
  }
  name = "TrieRouter";
  #node;
  constructor() {
    this.#node = new Node2();
  }
  add(method, path, handler) {
    const results = checkOptionalParameter(path);
    if (results) {
      for (let i = 0, len = results.length; i < len; i++) {
        this.#node.insert(method, results[i], handler);
      }
      return;
    }
    this.#node.insert(method, path, handler);
  }
  match(method, path) {
    return this.#node.search(method, path);
  }
};

// node_modules/hono/dist/hono.js
var Hono2 = class extends Hono {
  static {
    __name(this, "Hono");
  }
  /**
   * Creates an instance of the Hono class.
   *
   * @param options - Optional configuration options for the Hono instance.
   */
  constructor(options = {}) {
    super(options);
    this.router = options.router ?? new SmartRouter({
      routers: [new RegExpRouter(), new TrieRouter()]
    });
  }
};

// node_modules/hono/dist/middleware/cors/index.js
var cors = /* @__PURE__ */ __name((options) => {
  const opts = {
    origin: "*",
    allowMethods: ["GET", "HEAD", "PUT", "POST", "DELETE", "PATCH"],
    allowHeaders: [],
    exposeHeaders: [],
    ...options
  };
  const findAllowOrigin = ((optsOrigin) => {
    if (typeof optsOrigin === "string") {
      if (optsOrigin === "*") {
        return () => optsOrigin;
      } else {
        return (origin) => optsOrigin === origin ? origin : null;
      }
    } else if (typeof optsOrigin === "function") {
      return optsOrigin;
    } else {
      return (origin) => optsOrigin.includes(origin) ? origin : null;
    }
  })(opts.origin);
  const findAllowMethods = ((optsAllowMethods) => {
    if (typeof optsAllowMethods === "function") {
      return optsAllowMethods;
    } else if (Array.isArray(optsAllowMethods)) {
      return () => optsAllowMethods;
    } else {
      return () => [];
    }
  })(opts.allowMethods);
  return /* @__PURE__ */ __name(async function cors2(c, next) {
    function set(key, value) {
      c.res.headers.set(key, value);
    }
    __name(set, "set");
    const allowOrigin = await findAllowOrigin(c.req.header("origin") || "", c);
    if (allowOrigin) {
      set("Access-Control-Allow-Origin", allowOrigin);
    }
    if (opts.credentials) {
      set("Access-Control-Allow-Credentials", "true");
    }
    if (opts.exposeHeaders?.length) {
      set("Access-Control-Expose-Headers", opts.exposeHeaders.join(","));
    }
    if (c.req.method === "OPTIONS") {
      if (opts.origin !== "*") {
        set("Vary", "Origin");
      }
      if (opts.maxAge != null) {
        set("Access-Control-Max-Age", opts.maxAge.toString());
      }
      const allowMethods = await findAllowMethods(c.req.header("origin") || "", c);
      if (allowMethods.length) {
        set("Access-Control-Allow-Methods", allowMethods.join(","));
      }
      let headers = opts.allowHeaders;
      if (!headers?.length) {
        const requestHeaders = c.req.header("Access-Control-Request-Headers");
        if (requestHeaders) {
          headers = requestHeaders.split(/\s*,\s*/);
        }
      }
      if (headers?.length) {
        set("Access-Control-Allow-Headers", headers.join(","));
        c.res.headers.append("Vary", "Access-Control-Request-Headers");
      }
      c.res.headers.delete("Content-Length");
      c.res.headers.delete("Content-Type");
      return new Response(null, {
        headers: c.res.headers,
        status: 204,
        statusText: "No Content"
      });
    }
    await next();
    if (opts.origin !== "*") {
      c.header("Vary", "Origin", { append: true });
    }
  }, "cors2");
}, "cors");

// node_modules/hono/dist/utils/encode.js
var decodeBase64Url = /* @__PURE__ */ __name((str) => {
  return decodeBase64(str.replace(/_|-/g, (m) => ({ _: "/", "-": "+" })[m] ?? m));
}, "decodeBase64Url");
var encodeBase64Url = /* @__PURE__ */ __name((buf) => encodeBase64(buf).replace(/\/|\+/g, (m) => ({ "/": "_", "+": "-" })[m] ?? m), "encodeBase64Url");
var encodeBase64 = /* @__PURE__ */ __name((buf) => {
  let binary = "";
  const bytes = new Uint8Array(buf);
  for (let i = 0, len = bytes.length; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}, "encodeBase64");
var decodeBase64 = /* @__PURE__ */ __name((str) => {
  const binary = atob(str);
  const bytes = new Uint8Array(new ArrayBuffer(binary.length));
  const half = binary.length / 2;
  for (let i = 0, j = binary.length - 1; i <= half; i++, j--) {
    bytes[i] = binary.charCodeAt(i);
    bytes[j] = binary.charCodeAt(j);
  }
  return bytes;
}, "decodeBase64");

// node_modules/hono/dist/utils/jwt/jwa.js
var AlgorithmTypes = /* @__PURE__ */ ((AlgorithmTypes2) => {
  AlgorithmTypes2["HS256"] = "HS256";
  AlgorithmTypes2["HS384"] = "HS384";
  AlgorithmTypes2["HS512"] = "HS512";
  AlgorithmTypes2["RS256"] = "RS256";
  AlgorithmTypes2["RS384"] = "RS384";
  AlgorithmTypes2["RS512"] = "RS512";
  AlgorithmTypes2["PS256"] = "PS256";
  AlgorithmTypes2["PS384"] = "PS384";
  AlgorithmTypes2["PS512"] = "PS512";
  AlgorithmTypes2["ES256"] = "ES256";
  AlgorithmTypes2["ES384"] = "ES384";
  AlgorithmTypes2["ES512"] = "ES512";
  AlgorithmTypes2["EdDSA"] = "EdDSA";
  return AlgorithmTypes2;
})(AlgorithmTypes || {});

// node_modules/hono/dist/helper/adapter/index.js
var knownUserAgents = {
  deno: "Deno",
  bun: "Bun",
  workerd: "Cloudflare-Workers",
  node: "Node.js"
};
var getRuntimeKey = /* @__PURE__ */ __name(() => {
  const global = globalThis;
  const userAgentSupported = typeof navigator !== "undefined" && true;
  if (userAgentSupported) {
    for (const [runtimeKey, userAgent] of Object.entries(knownUserAgents)) {
      if (checkUserAgentEquals(userAgent)) {
        return runtimeKey;
      }
    }
  }
  if (typeof global?.EdgeRuntime === "string") {
    return "edge-light";
  }
  if (global?.fastly !== void 0) {
    return "fastly";
  }
  if (global?.process?.release?.name === "node") {
    return "node";
  }
  return "other";
}, "getRuntimeKey");
var checkUserAgentEquals = /* @__PURE__ */ __name((platform) => {
  const userAgent = "Cloudflare-Workers";
  return userAgent.startsWith(platform);
}, "checkUserAgentEquals");

// node_modules/hono/dist/utils/jwt/types.js
var JwtAlgorithmNotImplemented = class extends Error {
  static {
    __name(this, "JwtAlgorithmNotImplemented");
  }
  constructor(alg) {
    super(`${alg} is not an implemented algorithm`);
    this.name = "JwtAlgorithmNotImplemented";
  }
};
var JwtAlgorithmRequired = class extends Error {
  static {
    __name(this, "JwtAlgorithmRequired");
  }
  constructor() {
    super('JWT verification requires "alg" option to be specified');
    this.name = "JwtAlgorithmRequired";
  }
};
var JwtAlgorithmMismatch = class extends Error {
  static {
    __name(this, "JwtAlgorithmMismatch");
  }
  constructor(expected, actual) {
    super(`JWT algorithm mismatch: expected "${expected}", got "${actual}"`);
    this.name = "JwtAlgorithmMismatch";
  }
};
var JwtTokenInvalid = class extends Error {
  static {
    __name(this, "JwtTokenInvalid");
  }
  constructor(token) {
    super(`invalid JWT token: ${token}`);
    this.name = "JwtTokenInvalid";
  }
};
var JwtTokenNotBefore = class extends Error {
  static {
    __name(this, "JwtTokenNotBefore");
  }
  constructor(token) {
    super(`token (${token}) is being used before it's valid`);
    this.name = "JwtTokenNotBefore";
  }
};
var JwtTokenExpired = class extends Error {
  static {
    __name(this, "JwtTokenExpired");
  }
  constructor(token) {
    super(`token (${token}) expired`);
    this.name = "JwtTokenExpired";
  }
};
var JwtTokenIssuedAt = class extends Error {
  static {
    __name(this, "JwtTokenIssuedAt");
  }
  constructor(currentTimestamp, iat) {
    super(
      `Invalid "iat" claim, must be a valid number lower than "${currentTimestamp}" (iat: "${iat}")`
    );
    this.name = "JwtTokenIssuedAt";
  }
};
var JwtTokenIssuer = class extends Error {
  static {
    __name(this, "JwtTokenIssuer");
  }
  constructor(expected, iss) {
    super(`expected issuer "${expected}", got ${iss ? `"${iss}"` : "none"} `);
    this.name = "JwtTokenIssuer";
  }
};
var JwtHeaderInvalid = class extends Error {
  static {
    __name(this, "JwtHeaderInvalid");
  }
  constructor(header) {
    super(`jwt header is invalid: ${JSON.stringify(header)}`);
    this.name = "JwtHeaderInvalid";
  }
};
var JwtHeaderRequiresKid = class extends Error {
  static {
    __name(this, "JwtHeaderRequiresKid");
  }
  constructor(header) {
    super(`required "kid" in jwt header: ${JSON.stringify(header)}`);
    this.name = "JwtHeaderRequiresKid";
  }
};
var JwtSymmetricAlgorithmNotAllowed = class extends Error {
  static {
    __name(this, "JwtSymmetricAlgorithmNotAllowed");
  }
  constructor(alg) {
    super(`symmetric algorithm "${alg}" is not allowed for JWK verification`);
    this.name = "JwtSymmetricAlgorithmNotAllowed";
  }
};
var JwtAlgorithmNotAllowed = class extends Error {
  static {
    __name(this, "JwtAlgorithmNotAllowed");
  }
  constructor(alg, allowedAlgorithms) {
    super(`algorithm "${alg}" is not in the allowed list: [${allowedAlgorithms.join(", ")}]`);
    this.name = "JwtAlgorithmNotAllowed";
  }
};
var JwtTokenSignatureMismatched = class extends Error {
  static {
    __name(this, "JwtTokenSignatureMismatched");
  }
  constructor(token) {
    super(`token(${token}) signature mismatched`);
    this.name = "JwtTokenSignatureMismatched";
  }
};
var JwtPayloadRequiresAud = class extends Error {
  static {
    __name(this, "JwtPayloadRequiresAud");
  }
  constructor(payload) {
    super(`required "aud" in jwt payload: ${JSON.stringify(payload)}`);
    this.name = "JwtPayloadRequiresAud";
  }
};
var JwtTokenAudience = class extends Error {
  static {
    __name(this, "JwtTokenAudience");
  }
  constructor(expected, aud) {
    super(
      `expected audience "${Array.isArray(expected) ? expected.join(", ") : expected}", got "${aud}"`
    );
    this.name = "JwtTokenAudience";
  }
};
var CryptoKeyUsage = /* @__PURE__ */ ((CryptoKeyUsage2) => {
  CryptoKeyUsage2["Encrypt"] = "encrypt";
  CryptoKeyUsage2["Decrypt"] = "decrypt";
  CryptoKeyUsage2["Sign"] = "sign";
  CryptoKeyUsage2["Verify"] = "verify";
  CryptoKeyUsage2["DeriveKey"] = "deriveKey";
  CryptoKeyUsage2["DeriveBits"] = "deriveBits";
  CryptoKeyUsage2["WrapKey"] = "wrapKey";
  CryptoKeyUsage2["UnwrapKey"] = "unwrapKey";
  return CryptoKeyUsage2;
})(CryptoKeyUsage || {});

// node_modules/hono/dist/utils/jwt/utf8.js
var utf8Encoder = new TextEncoder();
var utf8Decoder = new TextDecoder();

// node_modules/hono/dist/utils/jwt/jws.js
async function signing(privateKey, alg, data) {
  const algorithm = getKeyAlgorithm(alg);
  const cryptoKey = await importPrivateKey(privateKey, algorithm);
  return await crypto.subtle.sign(algorithm, cryptoKey, data);
}
__name(signing, "signing");
async function verifying(publicKey, alg, signature, data) {
  const algorithm = getKeyAlgorithm(alg);
  const cryptoKey = await importPublicKey(publicKey, algorithm);
  return await crypto.subtle.verify(algorithm, cryptoKey, signature, data);
}
__name(verifying, "verifying");
function pemToBinary(pem) {
  return decodeBase64(pem.replace(/-+(BEGIN|END).*?-+/g, "").replace(/\s/g, ""));
}
__name(pemToBinary, "pemToBinary");
async function importPrivateKey(key, alg) {
  if (!crypto.subtle || !crypto.subtle.importKey) {
    throw new Error("`crypto.subtle.importKey` is undefined. JWT auth middleware requires it.");
  }
  if (isCryptoKey(key)) {
    if (key.type !== "private" && key.type !== "secret") {
      throw new Error(
        `unexpected key type: CryptoKey.type is ${key.type}, expected private or secret`
      );
    }
    return key;
  }
  const usages = [CryptoKeyUsage.Sign];
  if (typeof key === "object") {
    return await crypto.subtle.importKey("jwk", key, alg, false, usages);
  }
  if (key.includes("PRIVATE")) {
    return await crypto.subtle.importKey("pkcs8", pemToBinary(key), alg, false, usages);
  }
  return await crypto.subtle.importKey("raw", utf8Encoder.encode(key), alg, false, usages);
}
__name(importPrivateKey, "importPrivateKey");
async function importPublicKey(key, alg) {
  if (!crypto.subtle || !crypto.subtle.importKey) {
    throw new Error("`crypto.subtle.importKey` is undefined. JWT auth middleware requires it.");
  }
  if (isCryptoKey(key)) {
    if (key.type === "public" || key.type === "secret") {
      return key;
    }
    key = await exportPublicJwkFrom(key);
  }
  if (typeof key === "string" && key.includes("PRIVATE")) {
    const privateKey = await crypto.subtle.importKey("pkcs8", pemToBinary(key), alg, true, [
      CryptoKeyUsage.Sign
    ]);
    key = await exportPublicJwkFrom(privateKey);
  }
  const usages = [CryptoKeyUsage.Verify];
  if (typeof key === "object") {
    return await crypto.subtle.importKey("jwk", key, alg, false, usages);
  }
  if (key.includes("PUBLIC")) {
    return await crypto.subtle.importKey("spki", pemToBinary(key), alg, false, usages);
  }
  return await crypto.subtle.importKey("raw", utf8Encoder.encode(key), alg, false, usages);
}
__name(importPublicKey, "importPublicKey");
async function exportPublicJwkFrom(privateKey) {
  if (privateKey.type !== "private") {
    throw new Error(`unexpected key type: ${privateKey.type}`);
  }
  if (!privateKey.extractable) {
    throw new Error("unexpected private key is unextractable");
  }
  const jwk = await crypto.subtle.exportKey("jwk", privateKey);
  const { kty } = jwk;
  const { alg, e, n } = jwk;
  const { crv, x, y } = jwk;
  return { kty, alg, e, n, crv, x, y, key_ops: [CryptoKeyUsage.Verify] };
}
__name(exportPublicJwkFrom, "exportPublicJwkFrom");
function getKeyAlgorithm(name) {
  switch (name) {
    case "HS256":
      return {
        name: "HMAC",
        hash: {
          name: "SHA-256"
        }
      };
    case "HS384":
      return {
        name: "HMAC",
        hash: {
          name: "SHA-384"
        }
      };
    case "HS512":
      return {
        name: "HMAC",
        hash: {
          name: "SHA-512"
        }
      };
    case "RS256":
      return {
        name: "RSASSA-PKCS1-v1_5",
        hash: {
          name: "SHA-256"
        }
      };
    case "RS384":
      return {
        name: "RSASSA-PKCS1-v1_5",
        hash: {
          name: "SHA-384"
        }
      };
    case "RS512":
      return {
        name: "RSASSA-PKCS1-v1_5",
        hash: {
          name: "SHA-512"
        }
      };
    case "PS256":
      return {
        name: "RSA-PSS",
        hash: {
          name: "SHA-256"
        },
        saltLength: 32
        // 256 >> 3
      };
    case "PS384":
      return {
        name: "RSA-PSS",
        hash: {
          name: "SHA-384"
        },
        saltLength: 48
        // 384 >> 3
      };
    case "PS512":
      return {
        name: "RSA-PSS",
        hash: {
          name: "SHA-512"
        },
        saltLength: 64
        // 512 >> 3,
      };
    case "ES256":
      return {
        name: "ECDSA",
        hash: {
          name: "SHA-256"
        },
        namedCurve: "P-256"
      };
    case "ES384":
      return {
        name: "ECDSA",
        hash: {
          name: "SHA-384"
        },
        namedCurve: "P-384"
      };
    case "ES512":
      return {
        name: "ECDSA",
        hash: {
          name: "SHA-512"
        },
        namedCurve: "P-521"
      };
    case "EdDSA":
      return {
        name: "Ed25519",
        namedCurve: "Ed25519"
      };
    default:
      throw new JwtAlgorithmNotImplemented(name);
  }
}
__name(getKeyAlgorithm, "getKeyAlgorithm");
function isCryptoKey(key) {
  const runtime = getRuntimeKey();
  if (runtime === "node" && !!crypto.webcrypto) {
    return key instanceof crypto.webcrypto.CryptoKey;
  }
  return key instanceof CryptoKey;
}
__name(isCryptoKey, "isCryptoKey");

// node_modules/hono/dist/utils/jwt/jwt.js
var encodeJwtPart = /* @__PURE__ */ __name((part) => encodeBase64Url(utf8Encoder.encode(JSON.stringify(part)).buffer).replace(/=/g, ""), "encodeJwtPart");
var encodeSignaturePart = /* @__PURE__ */ __name((buf) => encodeBase64Url(buf).replace(/=/g, ""), "encodeSignaturePart");
var decodeJwtPart = /* @__PURE__ */ __name((part) => JSON.parse(utf8Decoder.decode(decodeBase64Url(part))), "decodeJwtPart");
function isTokenHeader(obj) {
  if (typeof obj === "object" && obj !== null) {
    const objWithAlg = obj;
    return "alg" in objWithAlg && Object.values(AlgorithmTypes).includes(objWithAlg.alg) && (!("typ" in objWithAlg) || objWithAlg.typ === "JWT");
  }
  return false;
}
__name(isTokenHeader, "isTokenHeader");
var sign = /* @__PURE__ */ __name(async (payload, privateKey, alg = "HS256") => {
  const encodedPayload = encodeJwtPart(payload);
  let encodedHeader;
  if (typeof privateKey === "object" && "alg" in privateKey) {
    alg = privateKey.alg;
    encodedHeader = encodeJwtPart({ alg, typ: "JWT", kid: privateKey.kid });
  } else {
    encodedHeader = encodeJwtPart({ alg, typ: "JWT" });
  }
  const partialToken = `${encodedHeader}.${encodedPayload}`;
  const signaturePart = await signing(privateKey, alg, utf8Encoder.encode(partialToken));
  const signature = encodeSignaturePart(signaturePart);
  return `${partialToken}.${signature}`;
}, "sign");
var verify = /* @__PURE__ */ __name(async (token, publicKey, algOrOptions) => {
  if (!algOrOptions) {
    throw new JwtAlgorithmRequired();
  }
  const {
    alg,
    iss,
    nbf = true,
    exp = true,
    iat = true,
    aud
  } = typeof algOrOptions === "string" ? { alg: algOrOptions } : algOrOptions;
  if (!alg) {
    throw new JwtAlgorithmRequired();
  }
  const tokenParts = token.split(".");
  if (tokenParts.length !== 3) {
    throw new JwtTokenInvalid(token);
  }
  const { header, payload } = decode(token);
  if (!isTokenHeader(header)) {
    throw new JwtHeaderInvalid(header);
  }
  if (header.alg !== alg) {
    throw new JwtAlgorithmMismatch(alg, header.alg);
  }
  const now = Math.floor(Date.now() / 1e3);
  if (nbf && payload.nbf !== void 0) {
    if (typeof payload.nbf !== "number" || !Number.isFinite(payload.nbf) || payload.nbf > now) {
      throw new JwtTokenNotBefore(token);
    }
  }
  if (exp && payload.exp !== void 0) {
    if (typeof payload.exp !== "number" || !Number.isFinite(payload.exp) || payload.exp <= now) {
      throw new JwtTokenExpired(token);
    }
  }
  if (iat && payload.iat !== void 0) {
    if (typeof payload.iat !== "number" || !Number.isFinite(payload.iat) || now < payload.iat) {
      throw new JwtTokenIssuedAt(now, payload.iat);
    }
  }
  if (iss) {
    if (!payload.iss) {
      throw new JwtTokenIssuer(iss, null);
    }
    if (typeof iss === "string" && payload.iss !== iss) {
      throw new JwtTokenIssuer(iss, payload.iss);
    }
    if (iss instanceof RegExp && !iss.test(payload.iss)) {
      throw new JwtTokenIssuer(iss, payload.iss);
    }
  }
  if (aud) {
    if (!payload.aud) {
      throw new JwtPayloadRequiresAud(payload);
    }
    const audiences = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
    const matched = audiences.some(
      (payloadAud) => aud instanceof RegExp ? aud.test(payloadAud) : typeof aud === "string" ? payloadAud === aud : Array.isArray(aud) && aud.includes(payloadAud)
    );
    if (!matched) {
      throw new JwtTokenAudience(aud, payload.aud);
    }
  }
  const headerPayload = token.substring(0, token.lastIndexOf("."));
  const verified = await verifying(
    publicKey,
    alg,
    decodeBase64Url(tokenParts[2]),
    utf8Encoder.encode(headerPayload)
  );
  if (!verified) {
    throw new JwtTokenSignatureMismatched(token);
  }
  return payload;
}, "verify");
var symmetricAlgorithms = [
  AlgorithmTypes.HS256,
  AlgorithmTypes.HS384,
  AlgorithmTypes.HS512
];
var verifyWithJwks = /* @__PURE__ */ __name(async (token, options, init) => {
  const verifyOpts = options.verification || {};
  const header = decodeHeader(token);
  if (!isTokenHeader(header)) {
    throw new JwtHeaderInvalid(header);
  }
  if (!header.kid) {
    throw new JwtHeaderRequiresKid(header);
  }
  if (symmetricAlgorithms.includes(header.alg)) {
    throw new JwtSymmetricAlgorithmNotAllowed(header.alg);
  }
  if (!options.allowedAlgorithms.includes(header.alg)) {
    throw new JwtAlgorithmNotAllowed(header.alg, options.allowedAlgorithms);
  }
  let verifyKeys = options.keys ? [...options.keys] : void 0;
  if (options.jwks_uri) {
    const response = await fetch(options.jwks_uri, init);
    if (!response.ok) {
      throw new Error(`failed to fetch JWKS from ${options.jwks_uri}`);
    }
    const data = await response.json();
    if (!data.keys) {
      throw new Error('invalid JWKS response. "keys" field is missing');
    }
    if (!Array.isArray(data.keys)) {
      throw new Error('invalid JWKS response. "keys" field is not an array');
    }
    verifyKeys ??= [];
    verifyKeys.push(...data.keys);
  } else if (!verifyKeys) {
    throw new Error('verifyWithJwks requires options for either "keys" or "jwks_uri" or both');
  }
  const matchingKey = verifyKeys.find((key) => key.kid === header.kid);
  if (!matchingKey) {
    throw new JwtTokenInvalid(token);
  }
  if (matchingKey.alg && matchingKey.alg !== header.alg) {
    throw new JwtAlgorithmMismatch(matchingKey.alg, header.alg);
  }
  return await verify(token, matchingKey, {
    alg: header.alg,
    ...verifyOpts
  });
}, "verifyWithJwks");
var decode = /* @__PURE__ */ __name((token) => {
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new JwtTokenInvalid(token);
  }
  try {
    const header = decodeJwtPart(parts[0]);
    const payload = decodeJwtPart(parts[1]);
    return {
      header,
      payload
    };
  } catch {
    throw new JwtTokenInvalid(token);
  }
}, "decode");
var decodeHeader = /* @__PURE__ */ __name((token) => {
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new JwtTokenInvalid(token);
  }
  try {
    return decodeJwtPart(parts[0]);
  } catch {
    throw new JwtTokenInvalid(token);
  }
}, "decodeHeader");

// node_modules/hono/dist/utils/jwt/index.js
var Jwt = { sign, verify, decode, verifyWithJwks };

// node_modules/hono/dist/middleware/jwt/jwt.js
var verifyWithJwks2 = Jwt.verifyWithJwks;
var verify2 = Jwt.verify;
var decode2 = Jwt.decode;
var sign2 = Jwt.sign;

// src/index.ts
var app = new Hono2();
var localD1Instance = null;
var localKVInstance = null;
app.use("*", async (c, next) => {
  if (!c.env) {
    c.env = {};
  }
  if (!c.env.DB && !localD1Instance) {
    try {
      const { DatabaseSync } = await import("node:sqlite");
      const path = await import("path");
      const fs = await import("fs");
      let dbPath = path.join(process.cwd(), "academypro.db");
      if (!fs.existsSync(dbPath)) {
        dbPath = path.join(process.cwd(), "usport.db");
      }
      if (fs.existsSync(dbPath)) {
        const dbSync = new DatabaseSync(dbPath);
        localD1Instance = {
          prepare(sql) {
            return {
              bind(...params) {
                return {
                  async all() {
                    const results = dbSync.prepare(sql).all(...params);
                    return { results, success: true };
                  },
                  async get() {
                    return dbSync.prepare(sql).get(...params) || null;
                  },
                  async first() {
                    return dbSync.prepare(sql).get(...params) || null;
                  },
                  async run() {
                    const res = dbSync.prepare(sql).run(...params);
                    return {
                      success: true,
                      meta: {
                        last_row_id: res.lastInsertRowid,
                        changes: res.changes
                      }
                    };
                  }
                };
              },
              async get() {
                return dbSync.prepare(sql).get() || null;
              },
              async first() {
                return dbSync.prepare(sql).get() || null;
              },
              async all() {
                const results = dbSync.prepare(sql).all();
                return { results, success: true };
              }
            };
          }
        };
      }
    } catch (e) {
      console.warn("Local database fallback failed:", e);
    }
  }
  if (!c.env.KV && !localKVInstance) {
    const store = /* @__PURE__ */ new Map();
    localKVInstance = {
      async put(key, val) {
        store.set(key, val);
      },
      async get(key) {
        return store.get(key) || null;
      },
      async delete(key) {
        store.delete(key);
      }
    };
  }
  await next();
});
function getDB(c) {
  return c.env?.DB || localD1Instance;
}
__name(getDB, "getDB");
function getKV(c) {
  return c.env?.KV || localKVInstance;
}
__name(getKV, "getKV");
app.use("*", cors({
  origin: /* @__PURE__ */ __name((origin) => origin || "*", "origin"),
  allowHeaders: ["Content-Type", "Authorization", "X-Internal-API-Key", "X-Api-Key", "If-None-Match", "X-Requested-With"],
  allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
  exposeHeaders: ["Content-Length", "ETag"],
  maxAge: 86400,
  credentials: true
}));
app.options("*", (c) => {
  return c.text("", 204);
});
app.use("*", async (c, next) => {
  const url = new URL(c.req.url);
  if (url.pathname !== "/" && url.pathname.endsWith("/")) {
    url.pathname = url.pathname.slice(0, -1);
    return c.redirect(url.toString(), 301);
  }
  await next();
});
app.onError((err, c) => {
  console.error("[Global Error Handler] Error:", err);
  const status = err instanceof SyntaxError ? 400 : 500;
  return c.json({
    success: false,
    message: err.message || "Internal Server Error"
  }, status);
});
function generateSecureOTP() {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  const otpNumber = 1e5 + array[0] % 9e5;
  return otpNumber.toString();
}
__name(generateSecureOTP, "generateSecureOTP");
function generatePrimaryKey(prefix = "id") {
  const uuid = typeof crypto !== "undefined" && crypto.randomUUID ? crypto.randomUUID().replace(/-/g, "").substring(0, 8) : Math.random().toString(36).substring(2, 10);
  return `${prefix}_${Date.now()}_${uuid}`;
}
__name(generatePrimaryKey, "generatePrimaryKey");
var getSecret = /* @__PURE__ */ __name((c) => {
  const secret = c.env?.JWT_SECRET;
  if (!secret) {
    throw new Error("JWT_SECRET environment variable is missing.");
  }
  return secret;
}, "getSecret");
function calculateAutoScore(stats) {
  const {
    tacklesMade,
    tacklesMissed,
    carries,
    metresGained,
    errors,
    penalties,
    workRate,
    overallRating
  } = stats;
  const missedAdjustment = tacklesMissed === 0 ? 0.01 : tacklesMissed;
  const tackleAccuracy = tacklesMade / (tacklesMade + missedAdjustment) * 2;
  const carriesTerm = carries / 10;
  const metresTerm = metresGained / 50;
  const discipline = Math.max(0, 1 - (errors + penalties) / 5);
  const workRateTerm = workRate / 5 * 2.5;
  const overallRatingTerm = overallRating / 5 * 2.5;
  const totalPoints = tackleAccuracy + carriesTerm + metresTerm + discipline + workRateTerm + overallRatingTerm;
  let autoScore = totalPoints / 10 * 5;
  autoScore = Math.round(autoScore * 10) / 10;
  autoScore = Math.max(0, Math.min(5, autoScore));
  const totalTackles = tacklesMade + tacklesMissed;
  const tacklePercentage = totalTackles > 0 ? tacklesMade / totalTackles : 0;
  let category = "\u{1F534} Developing";
  if (autoScore >= 4) {
    category = "\u{1F7E2} Excelling";
  } else if (autoScore >= 3) {
    category = "\u{1F7E1} On Track";
  } else if (autoScore >= 2) {
    category = "\u{1F7E0} At Risk";
  }
  return { autoScore, tacklePercentage, category };
}
__name(calculateAutoScore, "calculateAutoScore");
async function sendTransactionalEmail(c, options) {
  let emailSent = false;
  const env = c.env;
  if (env && env.EMAIL) {
    try {
      const { EmailMessage } = await import("cloudflare:email");
      const mimeMessage = `From: ${options.fromName} <${options.fromEmail}>
To: ${options.to}
Subject: ${options.subject}
Mime-Version: 1.0
Content-Type: text/html; charset=utf-8

${options.htmlContent}`;
      const emailMessage = new EmailMessage(
        options.fromEmail,
        options.to,
        mimeMessage
      );
      await env.EMAIL.send(emailMessage);
      emailSent = true;
      console.log(`[EMAIL] Sent native email to ${options.to}`);
    } catch (err) {
      console.error("[EMAIL] Cloudflare native send failed:", err);
    }
  }
  if (!emailSent) {
    try {
      const response = await fetch("https://web.codeways.co/api/send-email", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          to: options.to,
          subject: options.subject,
          text: options.textContent,
          html: options.htmlContent
        }),
        signal: AbortSignal.timeout(4e3)
      });
      if (response.ok) {
        emailSent = true;
        console.log(`[EMAIL] Sent via CodeWays API gateway to ${options.to}`);
      } else {
        const text = await response.text();
        console.error(`[EMAIL] CodeWays gateway failed: ${text}`);
      }
    } catch (err) {
      console.error("[EMAIL] CodeWays gateway fetch failed:", err);
    }
  }
  if (!emailSent) {
    console.warn(`[EMAIL WARNING] Failed to deliver email to ${options.to} via all gateways. Fallback printed to console.`);
  }
}
__name(sendTransactionalEmail, "sendTransactionalEmail");
app.post("/api/auth/send-otp", async (c) => {
  const { email } = await c.req.json();
  if (!email) {
    return c.json({ success: false, message: "Email is required" }, 400);
  }
  const db = getDB(c);
  const kv = getKV(c);
  if (!db) {
    return c.json({ success: false, message: "Local database usport.db not found" }, 500);
  }
  const query = "SELECT * FROM users WHERE email = ?";
  let user;
  try {
    user = await db.prepare(query).bind(email.trim().toLowerCase()).first();
  } catch (err) {
    return c.json({ success: false, message: "Database query failed", error: err.message }, 500);
  }
  if (!user) {
    return c.json({ success: false, message: "Access Denied: Account not found." }, 403);
  }
  const otp = generateSecureOTP();
  await kv.put(`otp:${email.trim().toLowerCase()}`, otp, { expirationTtl: 300 });
  const emailHtml = `<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; background-color: #FAF8FF; color: #131B2E; margin: 0; padding: 20px; }
    .container { max-width: 500px; background-color: #ffffff; border: 1px solid #E2E8F0; border-radius: 16px; padding: 32px; margin: 0 auto; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.02); }
    .header { text-align: center; margin-bottom: 24px; }
    .title { font-size: 26px; font-weight: 900; color: #003EC7; margin: 0; letter-spacing: -1.0px; }
    .content { font-size: 15px; line-height: 1.5; color: #434656; margin-bottom: 24px; }
    .code-box { background-color: #F2F3FF; border-radius: 12px; padding: 20px; text-align: center; font-size: 32px; font-weight: 900; color: #003EC7; letter-spacing: 4px; margin: 24px 0; }
    .footer { text-align: center; font-size: 12px; color: #737688; margin-top: 32px; border-top: 1px solid #E2E8F0; padding-top: 16px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 class="title">AcademyPro</h1>
    </div>
    <div class="content">
      <p>Hello,</p>
      <p>Your one-time verification code to sign in to AcademyPro is below. This code is valid for 5 minutes.</p>
      <div class="code-box">${otp}</div>
      <p>If you did not request this code, please ignore this email.</p>
    </div>
    <div class="footer">
      <p>\xA9 2026 CodeWays PTY Ltd. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`;
  const emailText = `Hello,

Your one-time verification code to sign in to AcademyPro is: ${otp}

This code is valid for 5 minutes.

\xA9 2026 CodeWays PTY Ltd.`;
  await sendTransactionalEmail(c, {
    to: email.trim().toLowerCase(),
    fromName: "AcademyPro App",
    fromEmail: "noreply@web.codeways.co",
    // Default fallback sender domain
    subject: "AcademyPro Login OTP",
    htmlContent: emailHtml,
    textContent: emailText
  });
  console.log(`[EMAIL SEND] To: ${email} | Subject: AcademyPro Login OTP | Code: ${otp}`);
  return c.json({
    success: true,
    message: "OTP sent successfully to email."
  });
});
app.post("/api/auth/verify-otp", async (c) => {
  const { email, otp } = await c.req.json();
  if (!email || !otp) {
    return c.json({ success: false, message: "Email and OTP are required" }, 400);
  }
  const db = getDB(c);
  const kv = getKV(c);
  const cachedOtp = await kv.get(`otp:${email.trim().toLowerCase()}`);
  if (!cachedOtp) {
    return c.json({ success: false, message: "OTP expired or not found. Try again." }, 400);
  }
  if (cachedOtp !== otp.trim()) {
    return c.json({ success: false, message: "Invalid OTP code. Access Denied." }, 401);
  }
  const query = "SELECT u.id, u.email, u.first_name, u.last_name, u.role, u.school_id, s.name as school_name FROM users u LEFT JOIN schools s ON u.school_id = s.id WHERE u.email = ?";
  let user = await db.prepare(query).bind(email.trim().toLowerCase()).first();
  if (!user) {
    user = await db.prepare("SELECT id, email, first_name, last_name, role, school_id FROM users WHERE email = ?").bind(email.trim().toLowerCase()).first();
  }
  if (!user) {
    return c.json({ success: false, message: "User profile not found after OTP verification" }, 404);
  }
  await kv.delete(`otp:${email.trim().toLowerCase()}`);
  const secret = getSecret(c);
  const payload = {
    sub: user.id,
    email: user.email,
    role: user.role,
    schoolId: user.school_id || null,
    exp: Math.floor(Date.now() / 1e3) + 12 * 60 * 60
    // 12 hours expiration
  };
  const token = await sign2(payload, secret);
  return c.json({
    success: true,
    data: {
      token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        schoolId: user.school_id || null,
        schoolName: user.school_name || null,
        firstName: user.first_name,
        lastName: user.last_name,
        first_name: user.first_name,
        last_name: user.last_name
      }
    }
  });
});
app.post("/api/auth/quick-login", async (c) => {
  const db = getDB(c);
  let body = {};
  try {
    body = await c.req.json();
  } catch (_) {
  }
  const targetEmail = (body.email || c.req.query("email") || "").trim().toLowerCase();
  let user = null;
  if (targetEmail) {
    user = await db.prepare("SELECT u.id, u.email, u.first_name, u.last_name, u.role, u.school_id, s.name as school_name FROM users u LEFT JOIN schools s ON u.school_id = s.id WHERE LOWER(u.email) = ? OR u.id = ?").bind(targetEmail, targetEmail).first();
  }
  if (!user) {
    user = await db.prepare("SELECT u.id, u.email, u.first_name, u.last_name, u.role, u.school_id, s.name as school_name FROM users u LEFT JOIN schools s ON u.school_id = s.id ORDER BY u.created_at ASC LIMIT 1").first();
  }
  if (!user) {
    return c.json({ success: false, message: "No registered user profile found in database" }, 404);
  }
  const secret = getSecret(c);
  const payload = {
    sub: user.id,
    email: user.email,
    role: user.role || "Coach",
    schoolId: user.school_id || "1",
    exp: Math.floor(Date.now() / 1e3) + 30 * 24 * 60 * 60
  };
  const token = await sign2(payload, secret);
  return c.json({
    success: true,
    message: `Authenticated successfully as ${user.first_name || "Coach"} ${user.last_name || ""} (${user.email})`,
    data: {
      token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role || "Coach",
        schoolId: user.school_id || "1",
        schoolName: user.school_name || "Ho\xEBrskool Oos-Moot",
        firstName: user.first_name,
        lastName: user.last_name,
        first_name: user.first_name,
        last_name: user.last_name
      }
    }
  });
});
app.get("/api/auth/profile", async (c) => {
  const db = getDB(c);
  const jwtPayload = c.get("jwtPayload");
  const authHeader = c.req.header("Authorization");
  let userId = jwtPayload?.sub || "";
  let email = jwtPayload?.email || c.req.query("email") || "";
  if (!userId && authHeader && authHeader.startsWith("Bearer ")) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify2(token, getSecret(c), "HS256");
      if (payload && payload.sub) {
        userId = payload.sub;
        email = payload.email || email;
      }
    } catch (_) {
    }
  }
  if (db && (userId || email)) {
    try {
      const user = await db.prepare("SELECT id, email, first_name, last_name, phone, role, school_id, avatar_url FROM users WHERE id = ? OR LOWER(email) = ?").bind(userId, (email || "").trim().toLowerCase()).first();
      if (user) {
        return c.json({
          success: true,
          data: {
            id: user.id,
            email: user.email,
            role: user.role,
            schoolId: user.school_id || 1,
            school_id: user.school_id || 1,
            firstName: user.first_name,
            lastName: user.last_name,
            first_name: user.first_name,
            last_name: user.last_name,
            phone: user.phone || "",
            avatar_url: user.avatar_url || ""
          }
        });
      }
    } catch (_) {
    }
  }
  return c.json({ success: false, message: "User not found" }, 404);
});
app.post("/api/auth/profile", async (c) => {
  const db = getDB(c);
  let body;
  try {
    body = await c.req.json();
  } catch (_) {
    return c.json({ success: false, message: "Invalid payload" }, 400);
  }
  const { id, email, firstName, first_name, lastName, last_name, avatar_url, avatarUrl, phone } = body || {};
  const jwtPayload = c.get("jwtPayload");
  let userId = id || jwtPayload?.sub || "";
  const userEmail = (email || jwtPayload?.email || "").trim().toLowerCase();
  const fName = firstName || first_name;
  const lName = lastName || last_name;
  const avatar = avatar_url || avatarUrl;
  const authHeader = c.req.header("Authorization");
  if (!userId && authHeader && authHeader.startsWith("Bearer ")) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify2(token, getSecret(c), "HS256");
      if (payload && payload.sub) {
        userId = payload.sub;
      }
    } catch (_) {
    }
  }
  if (!userId && !userEmail) {
    return c.json({ success: false, message: "User ID or Email is required" }, 400);
  }
  if (db) {
    try {
      await db.prepare(`
        UPDATE users
        SET first_name = COALESCE(?, first_name),
            last_name = COALESCE(?, last_name),
            phone = COALESCE(?, phone),
            avatar_url = COALESCE(?, avatar_url)
        WHERE id = ? OR LOWER(email) = ?
      `).bind(fName || null, lName || null, phone || null, avatar || null, userId, userEmail).run();
    } catch (err) {
      console.error("[API Error] Failed to update user profile in D1:", err);
      return c.json({ success: false, message: "Failed to update user profile in database", error: err.message }, 500);
    }
  }
  return c.json({
    success: true,
    message: "Profile updated successfully"
  });
});
app.post("/api/auth/send-email-change-otp", async (c) => {
  const db = getDB(c);
  let body;
  try {
    body = await c.req.json();
  } catch (_) {
    return c.json({ success: false, message: "Invalid payload" }, 400);
  }
  const { newEmail, currentEmail } = body;
  if (!newEmail || !currentEmail) {
    return c.json({ success: false, message: "Current email and new email are required" }, 400);
  }
  const cleanNewEmail = newEmail.trim().toLowerCase();
  const cleanCurrentEmail = currentEmail.trim().toLowerCase();
  const existingUser = await db.prepare("SELECT id FROM users WHERE email = ? AND email != ?").bind(cleanNewEmail, cleanCurrentEmail).first();
  if (existingUser) {
    return c.json({ success: false, message: "This email address is already registered to another account." }, 400);
  }
  const otp = generateSecureOTP();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1e3).toISOString();
  await db.prepare(`
    INSERT INTO user_otps (email, otp, expires_at)
    VALUES (?, ?, ?)
    ON CONFLICT(email) DO UPDATE SET otp = excluded.otp, expires_at = excluded.expires_at
  `).bind(cleanNewEmail, otp, expiresAt).run();
  await sendTransactionalEmail(c, {
    to: cleanNewEmail,
    fromName: "AcademyPro Support",
    fromEmail: "noreply@web.codeways.co",
    subject: "Verify Your New AcademyPro Email Address",
    htmlContent: `<div style="font-family: Arial, sans-serif; padding: 20px; color: #1E293B;">
      <h2 style="color: #003EC7;">Email Change Verification</h2>
      <p>You requested to update your primary email address on AcademyPro.</p>
      <p>Use the 6-digit verification code below to confirm this change:</p>
      <div style="font-size: 28px; font-weight: bold; color: #003EC7; letter-spacing: 4px; padding: 12px 0;">${otp}</div>
      <p style="font-size: 12px; color: #64748B;">This code is valid for 10 minutes. If you did not request this, please ignore this email.</p>
    </div>`,
    textContent: `Your verification code is ${otp}`
  });
  return c.json({
    success: true,
    message: `Verification code sent to ${cleanNewEmail}`
  });
});
app.post("/api/auth/verify-new-email", async (c) => {
  const db = getDB(c);
  let body;
  try {
    body = await c.req.json();
  } catch (_) {
    return c.json({ success: false, message: "Invalid payload" }, 400);
  }
  const { currentEmail, newEmail, otp } = body;
  if (!currentEmail || !newEmail || !otp) {
    return c.json({ success: false, message: "Current email, new email, and OTP code are required" }, 400);
  }
  const cleanCurrentEmail = currentEmail.trim().toLowerCase();
  const cleanNewEmail = newEmail.trim().toLowerCase();
  const otpRecord = await db.prepare("SELECT * FROM user_otps WHERE email = ? AND otp = ?").bind(cleanNewEmail, otp.trim()).first();
  if (!otpRecord) {
    return c.json({ success: false, message: "Invalid verification code. Please check your email and try again." }, 400);
  }
  const now = (/* @__PURE__ */ new Date()).toISOString();
  if (otpRecord.expires_at < now) {
    return c.json({ success: false, message: "Verification code has expired. Please request a new code." }, 400);
  }
  try {
    await db.prepare("UPDATE users SET email = ? WHERE email = ?").bind(cleanNewEmail, cleanCurrentEmail).run();
    await db.prepare("UPDATE parent_child_links SET player_email = ? WHERE player_email = ?").bind(cleanNewEmail, cleanCurrentEmail).run();
    await db.prepare("DELETE FROM user_otps WHERE email = ?").bind(cleanNewEmail).run();
    return c.json({
      success: true,
      message: `Email address updated successfully to ${cleanNewEmail}`,
      data: { updatedEmail: cleanNewEmail }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to update email address in database", error: err.message }, 500);
  }
});
async function enforceJwtAuth(c, next) {
  let token = "";
  const authHeader = c.req.header("Authorization");
  if (authHeader && authHeader.startsWith("Bearer ")) {
    token = authHeader.substring(7);
  }
  if (!token || token === "null" || token === "undefined") {
    token = c.req.query("token") || c.req.query("jwt") || c.req.query("access_token") || c.req.header("X-Access-Token") || c.req.header("X-Auth-Token") || "";
  }
  if (token && token !== "null" && token !== "undefined") {
    try {
      const payload = await verify2(token, getSecret(c), "HS256");
      c.set("jwtPayload", payload);
    } catch (_) {
    }
  }
  await next();
}
__name(enforceJwtAuth, "enforceJwtAuth");
app.use("/api/rosters/*", enforceJwtAuth);
app.use("/api/rosters", enforceJwtAuth);
app.use("/api/dashboard/*", enforceJwtAuth);
app.use("/api/dashboard", enforceJwtAuth);
app.use("/api/match-stats/*", enforceJwtAuth);
app.use("/api/match-stats", enforceJwtAuth);
app.use("/api/squads/*", enforceJwtAuth);
app.use("/api/squads", enforceJwtAuth);
app.use("/api/student-portal/*", enforceJwtAuth);
app.use("/api/student-portal", enforceJwtAuth);
app.use("/api/parent/*", enforceJwtAuth);
app.use("/api/parent", enforceJwtAuth);
app.use("/api/player/*", enforceJwtAuth);
app.use("/api/player", enforceJwtAuth);
app.use("/api/school/*", enforceJwtAuth);
app.use("/api/school", enforceJwtAuth);
app.use("/api/notifications/*", enforceJwtAuth);
app.use("/api/notifications", enforceJwtAuth);
app.use("/api/checkins/*", enforceJwtAuth);
app.use("/api/checkins", enforceJwtAuth);
app.use("/api/checkin/*", enforceJwtAuth);
app.use("/api/checkin", enforceJwtAuth);
app.use("/api/events/*", enforceJwtAuth);
app.use("/api/events", enforceJwtAuth);
app.get("/api/athletes", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const schoolId2 = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query("school_id") || c.req.query("schoolId") || "1";
  const db = getDB(c);
  try {
    const sId = String(schoolId2);
    let { results } = await db.prepare("SELECT * FROM players WHERE (school_id = ? OR CAST(school_id AS TEXT) = ?) ORDER BY first_name ASC").bind(sId, sId).all();
    if (!results || results.length === 0) {
      const fallbackRes = await db.prepare("SELECT * FROM players ORDER BY first_name ASC").all();
      results = fallbackRes.results || [];
    }
    return c.json({
      success: true,
      data: (results || []).map((p) => ({
        id: p.id,
        firstName: p.first_name,
        lastName: p.last_name,
        email: p.email || "",
        ageGroup: p.age_group,
        position: p.position,
        team: p.team || p.age_group
      }))
    });
  } catch (e) {
    return c.json({ success: false, message: e.message }, 500);
  }
});
app.post("/api/athletes", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const db = getDB(c);
  try {
    const body = await c.req.json();
    const { name, firstName, lastName, email, position, ageGroup, team, schoolId: schoolId2 } = body;
    const fullParts = (name || `${firstName || ""} ${lastName || ""}`).trim().split(" ");
    const fName = firstName || fullParts[0] || "";
    const lName = lastName || fullParts.slice(1).join(" ") || "";
    const targetSchool = schoolId2 || jwtPayload?.schoolId || jwtPayload?.school_id || 1;
    const assignedTeam = team || ageGroup || "";
    const playerId = body.id || generatePrimaryKey("plr");
    await db.prepare(`
      INSERT INTO players (id, school_id, first_name, last_name, email, age_group, position, team, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Active')
      ON CONFLICT(id) DO UPDATE SET
        first_name = excluded.first_name,
        last_name = excluded.last_name,
        email = excluded.email,
        position = excluded.position,
        team = excluded.team
    `).bind(playerId, targetSchool, fName, lName, email || "", ageGroup || team || "", position || "", assignedTeam).run();
    return c.json({ success: true, message: "Athlete saved successfully", data: { id: playerId, firstName: fName, lastName: lName, email, team: assignedTeam } });
  } catch (e) {
    return c.json({ success: false, message: e.message }, 500);
  }
});
app.put("/api/athletes/:id", async (c) => {
  const db = getDB(c);
  const id = c.req.param("id");
  try {
    const body = await c.req.json();
    const { name, firstName, lastName, email, position, status, team } = body;
    const fullParts = (name || `${firstName || ""} ${lastName || ""}`).trim().split(" ");
    const fName = firstName || fullParts[0] || "";
    const lName = lastName || fullParts.slice(1).join(" ") || "";
    const teamVal = body.team !== void 0 && body.team !== null ? body.team : null;
    await db.prepare(`
      UPDATE players
      SET first_name = ?, last_name = ?, email = ?, position = ?, status = ?,
          team = CASE WHEN ? IS NOT NULL AND ? != '' THEN ? ELSE team END
      WHERE id = ? OR (email = ? AND email != '')
    `).bind(fName, lName, email || "", position || "", status || "", teamVal, teamVal, teamVal, id, id).run();
    return c.json({ success: true, message: "Athlete updated successfully" });
  } catch (e) {
    return c.json({ success: false, message: e.message }, 500);
  }
});
app.delete("/api/athletes/:id", async (c) => {
  const db = getDB(c);
  const id = c.req.param("id");
  try {
    await db.prepare("DELETE FROM players WHERE id = ? OR email = ?").bind(id, id).run();
    await db.prepare("DELETE FROM squad_players WHERE player_id = ?").bind(id).run();
    return c.json({ success: true, message: "Athlete deleted successfully" });
  } catch (e) {
    return c.json({ success: false, message: e.message }, 500);
  }
});
var handleGetCoaches = /* @__PURE__ */ __name(async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const schoolId2 = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query("school_id") || c.req.query("schoolId") || "OVK";
  const db = getDB(c);
  try {
    const sId = String(schoolId2);
    let { results } = await db.prepare("SELECT id, first_name, last_name, name, email, role, phone_number, school_id FROM users WHERE (school_id = ? OR CAST(school_id AS TEXT) = ? OR role LIKE '%Coach%') ORDER BY first_name ASC").bind(sId, sId).all();
    if (!results || results.length === 0) {
      const allRes = await db.prepare("SELECT id, first_name, last_name, name, email, role, phone_number, school_id FROM users WHERE role LIKE '%Coach%' OR role LIKE '%Head%' OR role LIKE '%Admin%' ORDER BY first_name ASC").all();
      results = allRes.results || [];
    }
    return c.json({
      success: true,
      data: (results || []).map((u) => {
        const computedName = u.name && u.name.trim() || `${u.first_name || ""} ${u.last_name || ""}`.trim() || u.email || "Coach";
        return {
          id: u.id || u.email,
          name: computedName,
          firstName: u.first_name || computedName.split(" ")[0] || "",
          lastName: u.last_name || computedName.split(" ").slice(1).join(" ") || "",
          email: u.email,
          role: u.role || "Coach",
          phone: u.phone_number || "",
          schoolName: u.school_id || "OVK Academy"
        };
      })
    });
  } catch (e) {
    return c.json({ success: false, message: e.message }, 500);
  }
}, "handleGetCoaches");
app.get("/api/coaches", handleGetCoaches);
app.get("/api/dashboard/coaches", handleGetCoaches);
var handlePostCoach = /* @__PURE__ */ __name(async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const db = getDB(c);
  try {
    const body = await c.req.json();
    const { name, firstName, lastName, email, role, phone, schoolId: schoolId2 } = body;
    const coachEmail = (email || "").trim().toLowerCase();
    if (!coachEmail) {
      return c.json({ success: false, message: "Email is required for coach registration" }, 400);
    }
    const fullName = (name || `${firstName || ""} ${lastName || ""}`).trim() || "Coach";
    const fullParts = fullName.split(" ");
    const fName = firstName || fullParts[0] || "Coach";
    const lName = lastName || fullParts.slice(1).join(" ") || "";
    const coachRole = role || "Coach";
    const targetSchool = schoolId2 || body?.schoolName || body?.school_name || jwtPayload?.schoolId || jwtPayload?.school_id || "OVK";
    const userId = body.id || `cch_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    await db.prepare(`
      INSERT INTO users (id, school_id, first_name, last_name, name, email, role, phone_number)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(email) DO UPDATE SET
        first_name = excluded.first_name,
        last_name = excluded.last_name,
        name = excluded.name,
        role = excluded.role,
        phone_number = excluded.phone_number,
        school_id = excluded.school_id
    `).bind(userId, String(targetSchool), fName, lName, fullName, coachEmail, coachRole, phone || "").run();
    return c.json({
      success: true,
      message: "Coach saved successfully",
      data: { id: userId, email: coachEmail, name: fullName, role: coachRole, phone: phone || "", schoolName: targetSchool }
    });
  } catch (e) {
    return c.json({ success: false, message: e.message }, 500);
  }
}, "handlePostCoach");
app.post("/api/coaches", handlePostCoach);
app.post("/api/dashboard/coaches", handlePostCoach);
var handleDeleteCoach = /* @__PURE__ */ __name(async (c) => {
  const db = getDB(c);
  const rawId = c.req.param("id");
  const id = rawId ? decodeURIComponent(rawId).trim() : "";
  try {
    if (!id) {
      return c.json({ success: false, message: "Coach ID or email is required" }, 400);
    }
    await db.prepare("DELETE FROM users WHERE id = ? OR LOWER(email) = LOWER(?) OR CAST(id AS TEXT) = ?").bind(id, id, id).run();
    return c.json({ success: true, message: "Coach deleted successfully" });
  } catch (e) {
    return c.json({ success: false, message: e.message }, 500);
  }
}, "handleDeleteCoach");
app.delete("/api/coaches/:id", handleDeleteCoach);
app.delete("/api/dashboard/coaches/:id", handleDeleteCoach);
app.get("/api/test-results", async (c) => {
  const db = getDB(c);
  try {
    const { results } = await db.prepare("SELECT * FROM player_test_logs ORDER BY test_date DESC LIMIT 100").all();
    const formatted = (results || []).map((r) => ({
      id: r.id,
      eventId: r.event_id || "",
      athleteId: r.player_id || "",
      athleteName: r.athlete_name || "",
      testName: r.test_name || r.session_name || "",
      category: r.category || "",
      unit: r.unit || "",
      scoreValue: r.score_value || 0,
      testDate: r.test_date || r.created_at
    }));
    return c.json({ success: true, data: formatted });
  } catch (e) {
    return c.json({ success: false, message: e.message }, 500);
  }
});
var handleSaveTestResult = /* @__PURE__ */ __name(async (c) => {
  const db = getDB(c);
  try {
    const body = await c.req.json();
    const { id, eventId, athleteId, playerId, athleteName, testName, metricId, category, unit, scoreValue, score, testDate } = body;
    const resultId = id || generatePrimaryKey("tr");
    const pid = athleteId || playerId || "";
    const mId = metricId || testName || "general";
    const scoreVal = scoreValue !== void 0 ? parseFloat(scoreValue) : score !== void 0 ? parseFloat(score) : 0;
    const dateVal = testDate || (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
    await db.prepare(`
      INSERT INTO player_test_logs (id, event_id, player_id, metric_id, athlete_name, test_name, category, unit, score, score_value, test_date)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        score = excluded.score,
        score_value = excluded.score_value,
        test_date = excluded.test_date,
        athlete_name = excluded.athlete_name,
        test_name = excluded.test_name
    `).bind(
      resultId,
      eventId || "",
      pid,
      mId,
      athleteName || "",
      testName || "",
      category || "",
      unit || "",
      scoreVal,
      scoreVal,
      dateVal
    ).run();
    return c.json({ success: true, message: "Test result saved successfully", data: { id: resultId } });
  } catch (e) {
    return c.json({ success: false, message: e.message }, 500);
  }
}, "handleSaveTestResult");
app.post("/api/test-results", handleSaveTestResult);
app.post("/api/dashboard/test-results", handleSaveTestResult);
async function ensureSquadsTables(db) {
  if (!db) return;
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS squads (
        id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL,
        coach_id TEXT NOT NULL,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `).run();
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS squad_players (
        squad_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (squad_id, player_id)
      )
    `).run();
  } catch (err) {
    console.warn("Failed ensuring squads tables:", err);
  }
}
__name(ensureSquadsTables, "ensureSquadsTables");
async function getCoachSquadPlayerIds(db, coachId, schoolId2, role, ageGroupFilter) {
  await ensureSquadsTables(db);
  let squadRows = [];
  try {
    let sQuery = "SELECT id, code, name FROM squads WHERE school_id = ?";
    let sParams = [schoolId2];
    if (ageGroupFilter && ageGroupFilter !== "None" && ageGroupFilter !== "All") {
      sQuery += " AND (code = ? OR name = ? OR id = ?)";
      sParams.push(ageGroupFilter, ageGroupFilter, ageGroupFilter);
    }
    const { results } = await db.prepare(sQuery).bind(...sParams).all();
    squadRows = results || [];
  } catch (_) {
  }
  const squadIds = squadRows.map((s) => s.id);
  const squadCodes = squadRows.map((s) => s.code);
  const squadNames = squadRows.map((s) => s.name);
  const allSquadKeys = Array.from(/* @__PURE__ */ new Set([
    ...squadIds,
    ...squadCodes,
    ...squadNames,
    ...ageGroupFilter && ageGroupFilter !== "All" && ageGroupFilter !== "None" ? [ageGroupFilter] : []
  ]));
  const playerIdsSet = /* @__PURE__ */ new Set();
  if (allSquadKeys.length > 0) {
    const spPlaceholders = allSquadKeys.map(() => "?").join(",");
    try {
      const { results: spResults } = await db.prepare(`
        SELECT DISTINCT player_id FROM squad_players WHERE squad_id IN (${spPlaceholders})
      `).bind(...allSquadKeys).all();
      for (const r of spResults || []) {
        if (r.player_id) playerIdsSet.add(r.player_id);
      }
    } catch (_) {
    }
    try {
      const { results: smResults } = await db.prepare(`
        SELECT DISTINCT athlete_id FROM squad_members WHERE squad_id IN (${spPlaceholders})
      `).bind(...allSquadKeys).all();
      for (const r of smResults || []) {
        if (r.athlete_id) playerIdsSet.add(r.athlete_id);
      }
    } catch (_) {
    }
  }
  if (playerIdsSet.size === 0) {
    const targetSchool = schoolId2 || 1;
    try {
      if (ageGroupFilter && ageGroupFilter !== "All" && ageGroupFilter !== "None") {
        const { results: squadMatch } = await db.prepare(
          "SELECT id FROM players WHERE school_id = ? AND (LOWER(age_group) = LOWER(?) OR LOWER(team) = LOWER(?))"
        ).bind(targetSchool, ageGroupFilter, ageGroupFilter).all();
        for (const r of squadMatch || []) {
          if (r.id) playerIdsSet.add(r.id);
        }
      }
      if (playerIdsSet.size === 0) {
        const { results: allPlayers } = await db.prepare(
          "SELECT id FROM players WHERE school_id = ?"
        ).bind(targetSchool).all();
        for (const r of allPlayers || []) {
          if (r.id) playerIdsSet.add(r.id);
        }
      }
    } catch (err) {
      console.warn("[Observer Warning] Fallback roster query error:", err);
    }
  }
  const playerIds = Array.from(playerIdsSet);
  return {
    squadIds,
    playerIds,
    squadCodes: squadCodes.length > 0 ? squadCodes : ageGroupFilter ? [ageGroupFilter] : []
  };
}
__name(getCoachSquadPlayerIds, "getCoachSquadPlayerIds");
var handleGetSquads = /* @__PURE__ */ __name(async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const schoolId2 = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query("school_id") || c.req.query("schoolId") || "1";
  const coachId = jwtPayload?.sub || c.req.query("coach_id") || c.req.query("coachId");
  const db = getDB(c);
  await ensureSquadsTables(db);
  const sId = String(schoolId2);
  let query = `
    SELECT s.*, COUNT(DISTINCT sp.player_id) as playerCount
    FROM squads s
    LEFT JOIN squad_players sp ON (sp.squad_id = s.id OR sp.squad_id = s.code OR sp.squad_id = s.name)
    WHERE (s.school_id = ? OR CAST(s.school_id AS TEXT) = ?)
  `;
  let params = [sId, sId];
  if (coachId) {
    query += ` AND (s.coach_id = ? OR s.coach_id IS NULL OR s.coach_id = '')`;
    params.push(coachId);
  }
  query += ` GROUP BY s.id ORDER BY s.name ASC`;
  let results = [];
  try {
    const res = await db.prepare(query).bind(...params).all();
    results = res.results || [];
    if (results.length === 0) {
      const fallbackRes = await db.prepare(`
        SELECT s.*, COUNT(DISTINCT sp.player_id) as playerCount
        FROM squads s
        LEFT JOIN squad_players sp ON (sp.squad_id = s.id OR sp.squad_id = s.code OR sp.squad_id = s.name)
        GROUP BY s.id ORDER BY s.name ASC
      `).all();
      results = fallbackRes.results || [];
    }
  } catch (_) {
  }
  const uniqueSquadsMap = /* @__PURE__ */ new Map();
  results.forEach((s) => {
    const key = (s.name || s.code || s.id || "").trim().toLowerCase();
    if (!uniqueSquadsMap.has(key)) {
      uniqueSquadsMap.set(key, {
        id: s.id,
        name: s.name,
        ageGroup: s.code || s.age_group || s.name,
        code: s.code || s.age_group || s.name,
        description: s.description || "",
        playerCount: s.playerCount || 0,
        createdAt: s.created_at
      });
    }
  });
  const squads = Array.from(uniqueSquadsMap.values());
  return c.json({
    success: true,
    data: squads
  });
}, "handleGetSquads");
app.get("/api/squads", handleGetSquads);
app.get("/api/dashboard/squads", handleGetSquads);
var handlePostSquads = /* @__PURE__ */ __name(async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const coachId = jwtPayload?.sub || "USR-COACH-JAN777";
  const db = getDB(c);
  let body;
  try {
    body = await c.req.json();
  } catch (_) {
    return c.json({ success: false, message: "Invalid payload" }, 400);
  }
  const schoolId2 = jwtPayload?.schoolId || body?.schoolId || "1";
  const { id, name, ageGroup, code, description } = body;
  if (!code && !ageGroup) {
    return c.json({ success: false, message: "code or ageGroup is required" }, 400);
  }
  const squadName = name || "New Squad";
  const squadCode = (code || ageGroup).trim().toUpperCase();
  const squadId = id || `sq-${Date.now()}`;
  await ensureSquadsTables(db);
  try {
    await db.prepare(`
      INSERT INTO squads (id, school_id, coach_id, name, code, description)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(squadId, schoolId2, coachId, squadName, squadCode, description || "").run();
    try {
      const { results: matchingPlayers } = await db.prepare(
        "SELECT id FROM players WHERE school_id = ? AND (age_group = ? OR team = ?)"
      ).bind(schoolId2, squadCode, squadName).all();
      if (matchingPlayers && matchingPlayers.length > 0) {
        for (const p of matchingPlayers) {
          await db.prepare(
            "INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)"
          ).bind(squadId, p.id).run();
        }
      }
    } catch (_) {
    }
    console.log(`[Observer Log] Coach '${coachId}' created squad '${squadName}' (${squadCode}) [ID: ${squadId}]`);
    return c.json({
      success: true,
      message: "Squad created successfully",
      data: {
        id: squadId,
        name: squadName,
        ageGroup: squadCode,
        code: squadCode,
        description: description || ""
      }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to create squad", error: err.message }, 500);
  }
}, "handlePostSquads");
app.post("/api/squads", handlePostSquads);
app.post("/api/dashboard/squads", handlePostSquads);
var handleDeleteSquad = /* @__PURE__ */ __name(async (c) => {
  const squadId = c.req.param("id");
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Database connection unavailable" }, 500);
  }
  await ensureSquadsTables(db);
  try {
    await db.prepare("DELETE FROM squads WHERE id = ? OR name = ? OR code = ?").bind(squadId, squadId, squadId).run();
    await db.prepare("DELETE FROM squad_players WHERE squad_id = ? OR squad_id = ?").bind(squadId, squadId).run();
    return c.json({ success: true, message: "Squad deleted successfully" });
  } catch (err) {
    return c.json({ success: false, message: "Failed to delete squad", error: err.message }, 500);
  }
}, "handleDeleteSquad");
app.delete("/api/squads/:id", handleDeleteSquad);
app.delete("/api/dashboard/squads/:id", handleDeleteSquad);
app.get("/api/rosters/:age_group", async (c) => {
  const ageGroup = c.req.param("age_group");
  const jwtPayload = c.get("jwtPayload");
  const schoolId2 = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query("school_id") || c.req.query("schoolId") || 1;
  const coachId = jwtPayload?.sub || "USR-COACH-001";
  const role = jwtPayload?.role || "Coach";
  const db = getDB(c);
  if (!ageGroup || ageGroup === "None" || ageGroup === "Unassigned" || ageGroup === "No Squad") {
    return c.json({
      success: true,
      data: {
        ageGroup: ageGroup || "None",
        players: []
      }
    });
  }
  const { playerIds } = await getCoachSquadPlayerIds(db, coachId, schoolId2, role, ageGroup);
  if (playerIds.length === 0) {
    return c.json({
      success: true,
      data: {
        ageGroup,
        players: []
      }
    });
  }
  const placeholders = playerIds.map(() => "?").join(",");
  const playerSquadMap = {};
  try {
    const { results: spResults } = await db.prepare(`
      SELECT sp.player_id, s.id as squad_id, s.name as squad_name, s.code as squad_code
      FROM squad_players sp
      JOIN squads s ON s.id = sp.squad_id
      WHERE sp.player_id IN (${placeholders})
    `).bind(...playerIds).all();
    for (const row of spResults || []) {
      if (!playerSquadMap[row.player_id]) {
        playerSquadMap[row.player_id] = [];
      }
      playerSquadMap[row.player_id].push({
        id: row.squad_id,
        name: row.squad_name,
        code: row.squad_code
      });
    }
  } catch (_) {
  }
  try {
    const { results: smResults } = await db.prepare(`
      SELECT sm.athlete_id as player_id, s.id as squad_id, s.name as squad_name, s.code as squad_code
      FROM squad_members sm
      JOIN squads s ON s.id = sm.squad_id
      WHERE sm.athlete_id IN (${placeholders})
    `).bind(...playerIds).all();
    for (const row of smResults || []) {
      if (!playerSquadMap[row.player_id]) {
        playerSquadMap[row.player_id] = [];
      }
      if (!playerSquadMap[row.player_id].some((sq) => sq.id === row.squad_id)) {
        playerSquadMap[row.player_id].push({
          id: row.squad_id,
          name: row.squad_name,
          code: row.squad_code
        });
      }
    }
  } catch (_) {
  }
  const finalPlayers = [];
  try {
    const { results: pRes } = await db.prepare(`SELECT * FROM players WHERE id IN (${placeholders}) ORDER BY first_name ASC`).bind(...playerIds).all();
    if (pRes && pRes.length > 0) {
      for (const p of pRes) {
        finalPlayers.push({
          id: p.id,
          firstName: p.first_name || "",
          lastName: p.last_name || "",
          ageGroup: p.age_group || ageGroup,
          position: p.position || "Athlete",
          team: p.team || "U15 Squad",
          status: p.status || "",
          age: p.age ?? null,
          assignedSquads: playerSquadMap[p.id] || []
        });
      }
    }
  } catch (_) {
  }
  try {
    const { results: aRes } = await db.prepare(`SELECT * FROM athletes WHERE id IN (${placeholders})`).bind(...playerIds).all();
    if (aRes && aRes.length > 0) {
      for (const a of aRes) {
        if (!finalPlayers.some((p) => p.id === a.id)) {
          const parts = (a.name || "").trim().split(" ");
          const firstName = parts[0] || "Athlete";
          const lastName = parts.slice(1).join(" ") || "";
          finalPlayers.push({
            id: a.id,
            firstName,
            lastName,
            ageGroup,
            position: a.position || "Athlete",
            team: a.school_name || "U15 Squad",
            status: a.status || "",
            age: a.age ?? null,
            assignedSquads: playerSquadMap[a.id] || []
          });
        }
      }
    }
  } catch (_) {
  }
  try {
    const { results: logResults } = await db.prepare(`
      SELECT ptl.player_id, ptl.metric_id, ptl.score, ptl.test_date, ptl.session_name, tm.name as metric_name, tm.unit
      FROM player_test_logs ptl
      LEFT JOIN test_metrics tm ON tm.id = ptl.metric_id
      WHERE ptl.player_id IN (${placeholders})
      ORDER BY ptl.test_date DESC, ptl.created_at DESC
    `).bind(...playerIds).all();
    const playerLogsMap = {};
    for (const row of logResults || []) {
      if (!playerLogsMap[row.player_id]) {
        playerLogsMap[row.player_id] = [];
      }
      playerLogsMap[row.player_id].push({
        metricId: row.metric_id,
        metric_id: row.metric_id,
        metricName: row.metric_name || row.metric_id,
        metric_name: row.metric_name || row.metric_id,
        score: row.score,
        testDate: row.test_date,
        sessionName: row.session_name,
        unit: row.unit || ""
      });
    }
    for (const p of finalPlayers) {
      p.testLogs = playerLogsMap[p.id] || [];
      p.fitnessBaselines = playerLogsMap[p.id] || [];
    }
  } catch (_) {
  }
  return c.json({
    success: true,
    data: {
      ageGroup,
      players: finalPlayers
    }
  });
});
app.post("/api/players/:id/squads", async (c) => {
  const playerId = c.req.param("id");
  const body = await c.req.json();
  const { squadIds } = body;
  const db = getDB(c);
  if (!Array.isArray(squadIds)) {
    return c.json({ success: false, message: "squadIds must be an array" }, 400);
  }
  await ensureSquadsTables(db);
  try {
    let existingSquadIds = [];
    try {
      const { results } = await db.prepare("SELECT squad_id FROM squad_players WHERE player_id = ?").bind(playerId).all();
      existingSquadIds = (results || []).map((r) => r.squad_id);
    } catch (_) {
    }
    await db.prepare("DELETE FROM squad_players WHERE player_id = ?").bind(playerId).run();
    for (const squadId of squadIds) {
      await db.prepare("INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)").bind(squadId, playerId).run();
      let squad = null;
      try {
        squad = await db.prepare("SELECT id, code, name FROM squads WHERE id = ? OR code = ? OR name = ?").bind(squadId, squadId, squadId).first();
      } catch (_) {
      }
      if (squad) {
        await db.prepare("INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)").bind(squad.id, playerId).run();
        await db.prepare("INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)").bind(squad.code, playerId).run();
      }
    }
    const removedSquadIds = existingSquadIds.filter((id) => !squadIds.includes(id));
    for (const removedId of removedSquadIds) {
      let squad = null;
      try {
        squad = await db.prepare("SELECT id, code, name FROM squads WHERE id = ? OR code = ? OR name = ?").bind(removedId, removedId, removedId).first();
      } catch (_) {
      }
      const codesToClear = Array.from(/* @__PURE__ */ new Set([removedId, ...squad ? [squad.id, squad.code, squad.name] : []]));
      const ph = codesToClear.map(() => "?").join(",");
      await db.prepare(`
        UPDATE players
        SET age_group = CASE WHEN age_group IN (${ph}) THEN 'Unassigned' ELSE age_group END,
            team = CASE WHEN team IN (${ph}) THEN NULL ELSE team END
        WHERE id = ?
      `).bind(...codesToClear, ...codesToClear, playerId).run();
    }
    console.log(`[Observer Log] Updated squad assignments for player '${playerId}' to [${squadIds.join(", ")}]`);
    return c.json({
      success: true,
      message: "Player squad assignments updated successfully",
      data: { playerId, squadIds }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to update player squad assignments", error: err.message }, 500);
  }
});
app.get("/api/dashboard/summary", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const schoolId2 = jwtPayload?.schoolId;
  const coachId = jwtPayload?.sub;
  const role = jwtPayload?.role || "Coach";
  const ageGroup = c.req.query("age_group") || c.req.query("ageGroup");
  const db = getDB(c);
  if (!schoolId2) {
    return c.json({ success: false, message: "schoolId is required" }, 400);
  }
  const { playerIds } = await getCoachSquadPlayerIds(db, coachId, schoolId2, role, ageGroup);
  if (playerIds.length === 0) {
    return c.json({
      success: true,
      data: {
        attendancePercent: 0,
        teamPerformanceAvg: 0,
        kpis: {
          totalPlayers: 0,
          uniReady: 0,
          onTrack: 0,
          atRisk: 0,
          danger: 0,
          flagged: 0
        }
      }
    });
  }
  const totalPlayers = playerIds.length;
  const placeholders = playerIds.map(() => "?").join(",");
  const avgPerformanceQuery = `SELECT AVG(auto_score) as avg FROM match_stats WHERE player_id IN (${placeholders})`;
  const avgRes = await db.prepare(avgPerformanceQuery).bind(...playerIds).first();
  const avgScore = avgRes && avgRes.avg ? Math.round(avgRes.avg * 10) / 10 : 0;
  const academicQuery = `
    SELECT player_id, AVG(grade_percentage) as avg_grade
    FROM academic_logs
    WHERE player_id IN (${placeholders})
    GROUP BY player_id
  `;
  let acads = [];
  try {
    const res = await db.prepare(academicQuery).bind(...playerIds).all();
    acads = res.results || [];
  } catch (_) {
  }
  let uniReadyCount = 0;
  let onTrackCount = 0;
  let atRiskCount = 0;
  let dangerCount = 0;
  acads.forEach((row) => {
    const score = row.avg_grade;
    if (score >= 65) uniReadyCount++;
    else if (score >= 60) onTrackCount++;
    else if (score >= 50) atRiskCount++;
    else dangerCount++;
  });
  const attendanceQuery = `
    SELECT COUNT(*) as total, SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) as present
    FROM attendance
    WHERE player_id IN (${placeholders})
  `;
  const attRes = await db.prepare(attendanceQuery).bind(...playerIds).first();
  const attendancePercent = attRes && attRes.total > 0 ? Math.round(attRes.present / attRes.total * 100) : 0;
  return c.json({
    success: true,
    data: {
      attendancePercent,
      teamPerformanceAvg: avgScore,
      kpis: {
        totalPlayers,
        uniReady: uniReadyCount,
        onTrack: onTrackCount,
        atRisk: atRiskCount,
        danger: dangerCount,
        flagged: atRiskCount + dangerCount
      }
    }
  });
});
app.get("/api/dashboard/flags", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const schoolId2 = jwtPayload?.schoolId;
  const coachId = jwtPayload?.sub;
  const role = jwtPayload?.role || "Coach";
  const ageGroup = c.req.query("age_group") || c.req.query("ageGroup");
  const db = getDB(c);
  if (!schoolId2) {
    return c.json({ success: false, message: "schoolId is required" }, 400);
  }
  const { playerIds } = await getCoachSquadPlayerIds(db, coachId, schoolId2, role, ageGroup);
  if (playerIds.length === 0) {
    return c.json({
      success: true,
      data: []
    });
  }
  const placeholders = playerIds.map(() => "?").join(",");
  const query = `
    SELECT 
      p.id, 
      p.first_name, 
      p.last_name, 
      p.age_group, 
      p.position, 
      p.team,
      (SELECT AVG(al.grade_percentage) FROM academic_logs al WHERE al.player_id = p.id) as avg_grade,
      (SELECT ms.auto_score FROM match_stats ms WHERE ms.player_id = p.id ORDER BY ms.match_date DESC LIMIT 1) as auto_score
    FROM players p
    WHERE p.id IN (${placeholders})
  `;
  let rows = [];
  try {
    const res = await db.prepare(query).bind(...playerIds).all();
    rows = res.results || [];
  } catch (err) {
    return c.json({ success: false, message: "Database query failed", error: err.message }, 500);
  }
  const flaggedList = [];
  for (const player of rows) {
    const avgGrade = player.avg_grade !== null ? Math.round(player.avg_grade * 10) / 10 : null;
    const latestScore = player.auto_score;
    let isFlagged = false;
    let reason = "";
    let categoryType = "Normal";
    if (avgGrade !== null && avgGrade < 60) {
      isFlagged = true;
      categoryType = avgGrade < 50 ? "Critical" : "Warning";
      reason = `Academic Drop: Average grade is ${avgGrade}%. Requires tutoring check-in.`;
    } else if (latestScore !== null && latestScore < 2) {
      isFlagged = true;
      categoryType = "Warning";
      reason = `Performance Decline: Latest Auto-Score dropped to ${latestScore} (Developing).`;
    }
    if (isFlagged) {
      flaggedList.push({
        id: player.id,
        firstName: player.first_name,
        lastName: player.last_name,
        ageGroup: player.age_group,
        position: player.position,
        team: player.team,
        flagReason: reason,
        severity: categoryType,
        avgGrade: avgGrade || 0,
        latestScore
      });
    }
  }
  return c.json({
    success: true,
    data: flaggedList
  });
});
async function purgeExpiredWorkoutImages(c, results) {
  const db = getDB(c);
  const r2 = c.env?.R2;
  const sevenDaysMs = 7 * 24 * 60 * 60 * 1e3;
  const nowMs = Date.now();
  for (const r of results) {
    if (!r.workout_image_path) continue;
    try {
      const eventDateMs = new Date(r.date).getTime();
      if (!isNaN(eventDateMs) && nowMs - eventDateMs > sevenDaysMs) {
        const imagePath = r.workout_image_path;
        if (r2 && typeof r2.delete === "function") {
          const key = imagePath.includes("/") ? imagePath.split("/").pop() : imagePath;
          if (key) {
            await r2.delete(key);
            console.log(`[Observer Log] [R2 PURGE] Deleted workout image '${key}' for event #${r.id} older than 7 days.`);
          }
        }
        await db.prepare("UPDATE events SET workout_image_path = NULL WHERE id = ?").bind(r.id).run();
        r.workout_image_path = null;
      }
    } catch (err) {
      console.warn(`[Observer Error] [R2 PURGE] Failed purging workout image for event #${r?.id}:`, err);
    }
  }
}
__name(purgeExpiredWorkoutImages, "purgeExpiredWorkoutImages");
var handleGetEvents = /* @__PURE__ */ __name(async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const reqSchoolId = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query("school_id") || c.req.query("schoolId");
  const ageGroup = c.req.query("age_group") || c.req.query("ageGroup");
  const eventTypeParam = c.req.query("event_type") || c.req.query("eventType");
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Database connection unavailable" }, 500);
  }
  let query = "SELECT * FROM events WHERE 1=1";
  let params = [];
  if (reqSchoolId && reqSchoolId !== "ALL" && reqSchoolId !== "all") {
    const sId = String(reqSchoolId);
    query += ' AND (school_id = ? OR CAST(school_id AS TEXT) = ? OR school_id = "OVK" OR school_id = "1" OR school_id IS NULL)';
    params.push(sId, sId);
  }
  if (eventTypeParam) {
    const etLower = eventTypeParam.toLowerCase().trim();
    if (etLower === "fitness test" || etLower === "test day" || etLower === "fitness" || etLower === "test") {
      query += " AND (LOWER(event_type) = 'fitness test' OR LOWER(event_type) = 'test day' OR LOWER(event_type) = 'fitness' OR LOWER(event_type) = 'test' OR LOWER(event_type) LIKE '%fitness%' OR LOWER(event_type) LIKE '%test%')";
    } else {
      query += " AND LOWER(event_type) = ?";
      params.push(etLower);
    }
  }
  if (ageGroup && ageGroup !== "All" && ageGroup !== "ALL") {
    const agTrim = ageGroup.trim();
    query += ' AND (LOWER(age_group) = LOWER(?) OR LOWER(team) = LOWER(?) OR LOWER(age_group) LIKE LOWER(?) OR LOWER(team) LIKE LOWER(?) OR age_group IS NULL OR age_group = "" OR team IS NULL OR team = "")';
    params.push(agTrim, agTrim, `%${agTrim}%`, `%${agTrim}%`);
  }
  query += " ORDER BY date DESC, start_time DESC";
  try {
    const { results } = await db.prepare(query).bind(...params).all();
    if (c.executionCtx && typeof c.executionCtx.waitUntil === "function") {
      c.executionCtx.waitUntil(purgeExpiredWorkoutImages(c, results || []));
    } else {
      purgeExpiredWorkoutImages(c, results || []).catch(() => {
      });
    }
    let events = (results || []).map((r) => ({
      id: r.id?.toString() || "",
      schoolId: r.school_id || schoolId,
      title: r.title,
      eventType: r.event_type,
      startTime: r.start_time,
      date: r.date,
      durationMins: r.duration_mins,
      location: r.location,
      isImportant: r.is_important === 1,
      completionCount: r.completion_count,
      ageGroup: r.age_group || "",
      team: r.team || r.age_group || "",
      workoutImagePath: r.workout_image_path,
      recurrenceRule: r.recurrence_rule || "Does Not Repeat",
      recurrenceEndDate: r.recurrence_end_date || null
    }));
    return c.json({
      success: true,
      data: events
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to fetch events", error: err.message }, 500);
  }
}, "handleGetEvents");
app.get("/api/dashboard/events", handleGetEvents);
app.get("/api/events", handleGetEvents);
var handleCreateEvent = /* @__PURE__ */ __name(async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Database connection unavailable" }, 500);
  }
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const schoolId2 = (jwtPayload?.schoolId || body?.schoolId || "1").trim();
  const { id, title, eventType, startTime, date, durationMins, location, isImportant, ageGroup, team, workoutImagePath, recurrenceRule, recurrenceEndDate } = body;
  const eventTitle = (title || "").trim();
  const eventLoc = (location || "").trim();
  const eventTime = (startTime || "").trim();
  const eventDt = (date || "").trim();
  const rawEventType = (eventType || "").trim();
  const targetAgeGroup = (ageGroup || "").trim();
  const assignedTeam = (team || "").trim();
  if (!eventTitle) {
    return c.json({ success: false, message: "Event title is required." }, 400);
  }
  if (!rawEventType) {
    return c.json({ success: false, message: "Event type is required." }, 400);
  }
  if (!eventTime) {
    return c.json({ success: false, message: "Start time is required." }, 400);
  }
  if (!/^\d{1,2}:\d{2}(:\d{2})?$/.test(eventTime)) {
    return c.json({ success: false, message: "Start time must be formatted as HH:mm (e.g. 15:30)." }, 400);
  }
  if (!eventDt) {
    return c.json({ success: false, message: "Event date is required." }, 400);
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(eventDt)) {
    return c.json({ success: false, message: "Event date must be formatted as YYYY-MM-DD." }, 400);
  }
  const todayStr = (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
  if (eventDt < todayStr) {
    return c.json({ success: false, message: "Events cannot be created in the past." }, 400);
  }
  if (!eventLoc) {
    return c.json({ success: false, message: "Event location is required." }, 400);
  }
  if (!targetAgeGroup && !assignedTeam) {
    return c.json({ success: false, message: "Target age group or assigned team is required." }, 400);
  }
  let evType = rawEventType;
  if (evType === "Field" || evType === "Field Practice") evType = "Field Session";
  if (evType === "Gym" || evType === "Gym Practice") evType = "Gym Session";
  if (evType === "Match" || evType === "Match Practice") evType = "Match Day";
  if (evType === "Test Day" || evType === "Test") evType = "Fitness Test";
  const eventId = id ? id.toString() : `EVT-${Date.now()}`;
  const finalAgeGroup = targetAgeGroup || assignedTeam;
  const finalTeam = assignedTeam || targetAgeGroup;
  const recRuleVal = (recurrenceRule || body.recurrence_rule || "Does Not Repeat").trim();
  const recEndDateVal = recurrenceEndDate || body.recurrence_end_date || null;
  const query = `
    INSERT INTO events (
      id, school_id, title, event_type, start_time, date, duration_mins, location, is_important, completion_count, age_group, team, workout_image_path, recurrence_rule, recurrence_end_date
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      title = excluded.title,
      event_type = excluded.event_type,
      start_time = excluded.start_time,
      date = excluded.date,
      duration_mins = excluded.duration_mins,
      location = excluded.location,
      is_important = excluded.is_important,
      age_group = excluded.age_group,
      team = excluded.team,
      workout_image_path = excluded.workout_image_path,
      recurrence_rule = excluded.recurrence_rule,
      recurrence_end_date = excluded.recurrence_end_date
  `;
  try {
    const isImpVal = isImportant === true || isImportant === 1 ? 1 : 0;
    const durMinsVal = durationMins ? parseInt(durationMins.toString(), 10) : null;
    const compCountVal = evType === "Gym Session" ? 0 : null;
    await db.prepare(query).bind(
      eventId,
      schoolId2,
      eventTitle,
      evType,
      eventTime,
      eventDt,
      durMinsVal,
      eventLoc,
      isImpVal,
      compCountVal,
      finalAgeGroup,
      finalTeam,
      workoutImagePath || null,
      recRuleVal,
      recEndDateVal
    ).run();
    console.log(`[Observer Log] Event '${eventId}' successfully created in Cloudflare D1 for school '${schoolId2}'.`);
    return c.json({
      success: true,
      message: "Event created successfully",
      data: {
        id: eventId,
        schoolId: schoolId2,
        title: eventTitle,
        eventType: evType,
        startTime: eventTime,
        date: eventDt,
        durationMins: durMinsVal,
        location: eventLoc,
        isImportant: isImpVal === 1,
        completionCount: compCountVal,
        ageGroup: finalAgeGroup,
        team: finalTeam,
        workoutImagePath: workoutImagePath || null,
        recurrenceRule: recRuleVal,
        recurrenceEndDate: recEndDateVal
      }
    }, 201);
  } catch (err) {
    console.error(`[Observer Error] Failed to create event '${eventId}':`, err);
    return c.json({ success: false, message: "Failed to create event", error: err.message }, 500);
  }
}, "handleCreateEvent");
app.post("/api/dashboard/events", handleCreateEvent);
app.post("/api/events", handleCreateEvent);
var handleUpdateEvent = /* @__PURE__ */ __name(async (c) => {
  const id = c.req.param("id");
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Database connection unavailable" }, 500);
  }
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const { title, eventType, startTime, date, durationMins, location, isImportant, ageGroup, team, workoutImagePath, recurrenceRule, recurrenceEndDate } = body;
  const eventTitle = (title || "").trim();
  const eventLoc = (location || "").trim();
  const eventTime = (startTime || "").trim();
  const eventDt = (date || "").trim();
  const rawEventType = (eventType || "").trim();
  const targetAgeGroup = (ageGroup || "").trim();
  const assignedTeam = (team || "").trim();
  if (!eventTitle) {
    return c.json({ success: false, message: "Event title is required." }, 400);
  }
  if (!rawEventType) {
    return c.json({ success: false, message: "Event type is required." }, 400);
  }
  if (!eventTime) {
    return c.json({ success: false, message: "Start time is required." }, 400);
  }
  if (!/^\d{1,2}:\d{2}(:\d{2})?$/.test(eventTime)) {
    return c.json({ success: false, message: "Start time must be formatted as HH:mm (e.g. 15:30)." }, 400);
  }
  if (!eventDt) {
    return c.json({ success: false, message: "Event date is required." }, 400);
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(eventDt)) {
    return c.json({ success: false, message: "Event date must be formatted as YYYY-MM-DD." }, 400);
  }
  if (!eventLoc) {
    return c.json({ success: false, message: "Event location is required." }, 400);
  }
  if (!targetAgeGroup && !assignedTeam) {
    return c.json({ success: false, message: "Target age group or assigned team is required." }, 400);
  }
  let evType = rawEventType;
  if (evType === "Field" || evType === "Field Practice") evType = "Field Session";
  if (evType === "Gym" || evType === "Gym Practice") evType = "Gym Session";
  if (evType === "Match" || evType === "Match Practice") evType = "Match Day";
  if (evType === "Test Day" || evType === "Test") evType = "Fitness Test";
  const isImpVal = isImportant === true || isImportant === 1 ? 1 : 0;
  const durMinsVal = durationMins ? parseInt(durationMins.toString(), 10) : null;
  const finalAgeGroup = targetAgeGroup || assignedTeam;
  const finalTeam = assignedTeam || targetAgeGroup;
  const recRuleVal = (recurrenceRule || body.recurrence_rule || "Does Not Repeat").trim();
  const recEndDateVal = recurrenceEndDate || body.recurrence_end_date || null;
  try {
    const query = `
      UPDATE events SET 
        title = ?, event_type = ?, start_time = ?, date = ?, duration_mins = ?, 
        location = ?, is_important = ?, age_group = ?, team = ?, workout_image_path = ?,
        recurrence_rule = ?, recurrence_end_date = ?
      WHERE CAST(id AS TEXT) = ? OR id = ?
    `;
    await db.prepare(query).bind(
      eventTitle,
      evType,
      eventTime,
      eventDt,
      durMinsVal,
      eventLoc,
      isImpVal,
      finalAgeGroup,
      finalTeam,
      workoutImagePath || null,
      recRuleVal,
      recEndDateVal,
      id.toString(),
      id.toString()
    ).run();
    console.log(`[Observer Log] Event '${id}' successfully updated in D1.`);
    return c.json({ success: true, message: "Event updated successfully" });
  } catch (err) {
    console.error(`[Observer Error] Failed updating event '${id}':`, err);
    return c.json({ success: false, message: "Failed to update event", error: err.message }, 500);
  }
}, "handleUpdateEvent");
app.post("/api/dashboard/events/:id", handleUpdateEvent);
app.put("/api/dashboard/events/:id", handleUpdateEvent);
app.post("/api/events/:id", handleUpdateEvent);
app.put("/api/events/:id", handleUpdateEvent);
var handleDeleteEvent = /* @__PURE__ */ __name(async (c) => {
  const id = c.req.param("id");
  const db = getDB(c);
  try {
    await db.prepare("DELETE FROM events WHERE CAST(id AS TEXT) = ? OR id = ?").bind(id.toString(), id.toString()).run();
    return c.json({ success: true, message: "Event deleted successfully" });
  } catch (err) {
    return c.json({ success: false, message: "Failed to delete event", error: err.message }, 500);
  }
}, "handleDeleteEvent");
app.delete("/api/dashboard/events/:id", handleDeleteEvent);
app.post("/api/dashboard/events/:id/delete", handleDeleteEvent);
app.delete("/api/events/:id", handleDeleteEvent);
app.post("/api/events/:id/delete", handleDeleteEvent);
app.get("/api/dashboard/actions", async (c) => {
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Database connection unavailable" }, 500);
  }
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS action_plans (
        id TEXT PRIMARY KEY,
        school_id TEXT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        deadline TEXT NOT NULL,
        date_added TEXT,
        is_completed INTEGER DEFAULT 0,
        completed_at TIMESTAMP,
        player_id TEXT,
        player_name TEXT,
        player_phone TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `).run();
    await db.prepare("ALTER TABLE action_plans ADD COLUMN completed_at TIMESTAMP").run().catch(() => {
    });
    await db.prepare(`
      DELETE FROM action_plans 
      WHERE is_completed = 1 
        AND completed_at IS NOT NULL 
        AND (strftime('%s', 'now') - strftime('%s', completed_at)) >= 86400
    `).run().catch(() => {
    });
    const { results } = await db.prepare("SELECT * FROM action_plans ORDER BY created_at DESC").all();
    const nowMs = Date.now();
    const twentyFourHoursMs = 24 * 60 * 60 * 1e3;
    const filteredRows = (results || []).filter((row) => {
      if (row.is_completed === 1 && row.completed_at) {
        const completedMs = new Date(row.completed_at).getTime();
        if (!isNaN(completedMs) && nowMs - completedMs >= twentyFourHoursMs) {
          return false;
        }
      }
      return true;
    });
    return c.json({
      success: true,
      data: filteredRows.map((row) => ({
        id: row.id,
        title: row.title,
        type: row.type,
        category: row.category || row.type,
        deadline: row.deadline,
        dateAdded: row.date_added || "Today",
        isCompleted: Boolean(row.is_completed),
        completedAt: row.completed_at || null,
        playerId: row.player_id,
        playerName: row.player_name || "",
        playerPhone: row.player_phone || "",
        notes: row.notes || ""
      }))
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to fetch action plans", error: err.message }, 500);
  }
});
app.post("/api/dashboard/actions", async (c) => {
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Database connection unavailable" }, 500);
  }
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const { id, title, type, category, deadline, playerId, playerName, notes } = body;
  const actionId = id || `ACT-${Date.now()}`;
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS action_plans (
        id TEXT PRIMARY KEY,
        school_id TEXT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        deadline TEXT NOT NULL,
        date_added TEXT,
        is_completed INTEGER DEFAULT 0,
        completed_at TIMESTAMP,
        player_id TEXT,
        player_name TEXT,
        player_phone TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `).run();
    await db.prepare(`
      INSERT INTO action_plans (id, title, type, category, deadline, date_added, is_completed, player_id, player_name, notes)
      VALUES (?, ?, ?, ?, ?, 'Today', 0, ?, ?, ?)
    `).bind(
      actionId,
      title ? title.trim() : "Coach Action Item",
      type ? type.trim() : "General",
      category ? category.trim() : "General",
      deadline ? deadline.trim() : "Today",
      playerId || null,
      playerName ? playerName.trim() : "",
      notes ? notes.trim() : ""
    ).run();
    return c.json({
      success: true,
      message: "Action plan created successfully",
      data: {
        id: actionId,
        title,
        type: type || "General",
        category: category || type || "General",
        deadline: deadline || "Today",
        isCompleted: false,
        playerId,
        playerName: playerName || ""
      }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to create action plan", error: err.message }, 500);
  }
});
app.post("/api/dashboard/actions/:id/toggle", async (c) => {
  const id = c.req.param("id");
  const db = getDB(c);
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS action_plans (
        id TEXT PRIMARY KEY,
        school_id TEXT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        deadline TEXT NOT NULL,
        date_added TEXT,
        is_completed INTEGER DEFAULT 0,
        completed_at TIMESTAMP,
        player_id TEXT,
        player_name TEXT,
        player_phone TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `).run();
    await db.prepare("ALTER TABLE action_plans ADD COLUMN completed_at TIMESTAMP").run().catch(() => {
    });
    await db.prepare(`
      UPDATE action_plans 
      SET is_completed = CASE WHEN is_completed = 1 THEN 0 ELSE 1 END,
          completed_at = CASE WHEN is_completed = 0 THEN CURRENT_TIMESTAMP ELSE NULL END
      WHERE id = ?
    `).bind(id).run();
    return c.json({ success: true, message: "Action plan status updated successfully" });
  } catch (err) {
    return c.json({ success: false, message: "Failed to update action plan status", error: err.message }, 500);
  }
});
app.post("/api/dashboard/actions/:id/delete", async (c) => {
  const id = c.req.param("id");
  const db = getDB(c);
  try {
    await db.prepare("DELETE FROM action_plans WHERE id = ?").bind(id).run();
    return c.json({ success: true, message: "Action plan deleted successfully" });
  } catch (err) {
    return c.json({ success: false, message: "Failed to delete action plan", error: err.message }, 500);
  }
});
app.get("/api/dashboard/rising-stars", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const schoolId2 = jwtPayload?.schoolId;
  const ageGroup = c.req.query("age_group") || c.req.query("ageGroup");
  const db = getDB(c);
  if (!schoolId2) {
    return c.json({ success: false, message: "schoolId is required" }, 400);
  }
  let query = `
    SELECT 
      p.id, 
      p.first_name, 
      p.last_name, 
      p.age_group, 
      p.position, 
      p.team,
      (SELECT AVG(al.grade_percentage) FROM academic_logs al WHERE al.player_id = p.id) as avg_grade
    FROM players p
    WHERE p.school_id = ?
  `;
  let params = [schoolId2];
  if (ageGroup) {
    query += " AND p.age_group = ?";
    params.push(ageGroup);
  }
  query += " ORDER BY p.first_name ASC LIMIT 5";
  try {
    let { results } = await db.prepare(query).bind(...params).all();
    const grp = ageGroup || "";
    if (!results || results.length === 0) {
      return c.json({
        success: true,
        data: []
      });
    }
    const stars = results.map((p) => {
      const firstName = p.first_name || "Player";
      const lastName = p.last_name || "";
      return {
        id: p.id,
        name: `${firstName} ${lastName}`.trim(),
        firstName,
        lastName,
        team: p.team || p.age_group || grp,
        position: p.position || "Athlete",
        ageGroup: p.age_group || grp,
        streakWeeks: 0,
        gymConsistencyWeeks: 0,
        gradeImprovement: p.avg_grade ? Math.round(p.avg_grade) : 0,
        attendancePercent: 0,
        gymProgressPercent: 0,
        highlights: "Consistently active squad member"
      };
    });
    return c.json({
      success: true,
      data: stars
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to retrieve rising stars", error: err.message }, 500);
  }
});
var handlePostCheckin = /* @__PURE__ */ __name(async (c) => {
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Database connection unavailable" }, 500);
  }
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const eventId = body.eventId || body.event_id || body.id || null;
  let date = body.date || body.checkInDate || body.eventDate;
  let checkedInPlayerIds = [];
  if (Array.isArray(body.checkedInPlayerIds)) {
    checkedInPlayerIds = body.checkedInPlayerIds;
  } else if (Array.isArray(body.playerIds)) {
    checkedInPlayerIds = body.playerIds;
  } else if (Array.isArray(body.athleteIds)) {
    checkedInPlayerIds = body.athleteIds;
  } else if (body.playerId || body.athleteId) {
    const singleId = body.playerId || body.athleteId;
    const isPresent = body.isPresent !== false && body.checkedIn !== false && body.status !== "Absent";
    if (singleId && isPresent) {
      checkedInPlayerIds = [singleId];
    }
  }
  if (!date && eventId) {
    try {
      const ev = await db.prepare("SELECT date FROM events WHERE id = ?").bind(eventId).first();
      if (ev && ev.date) date = ev.date;
    } catch (_) {
    }
  }
  if (!date) {
    date = (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
  }
  const sessType = body.sessionType || "Field";
  const checkedInSet = new Set(checkedInPlayerIds);
  let targetPlayerIds = [];
  const ageGrp = body.ageGroup;
  if (eventId) {
    try {
      const ev = await db.prepare("SELECT age_group, team FROM events WHERE id = ?").bind(eventId).first();
      const evGroup = ev?.age_group || ev?.team || ageGrp;
      if (evGroup) {
        const { results: pRes } = await db.prepare("SELECT id FROM players WHERE age_group = ? OR team = ?").bind(evGroup, evGroup).all();
        if (pRes) targetPlayerIds = pRes.map((r) => r.id);
      }
    } catch (_) {
    }
  }
  if (targetPlayerIds.length === 0 && ageGrp) {
    try {
      const { results: pRes } = await db.prepare("SELECT id FROM players WHERE age_group = ? OR team = ?").bind(ageGrp, ageGrp).all();
      if (pRes) targetPlayerIds = pRes.map((r) => r.id);
    } catch (_) {
    }
  }
  const allSessionPlayerIds = Array.from(/* @__PURE__ */ new Set([...targetPlayerIds, ...checkedInPlayerIds]));
  let recordedCount = 0;
  for (const playerId of allSessionPlayerIds) {
    const isPresent = checkedInSet.has(playerId);
    const statusVal = isPresent ? "Present" : "Absent";
    const evtIdStr = eventId ? eventId.toString() : `evt-${date}-${sessType}`;
    try {
      const sql = `
        INSERT INTO attendance (player_id, session_type, date, status, event_id, created_at)
        VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(player_id, event_id) DO UPDATE SET
          status = ?,
          date = ?,
          session_type = ?,
          created_at = CURRENT_TIMESTAMP
      `;
      await db.prepare(sql).bind(playerId, sessType, date, statusVal, evtIdStr, statusVal, date, sessType).run();
      if (isPresent) recordedCount++;
    } catch (e) {
      try {
        const legacySql = `
          INSERT INTO attendance (player_id, session_type, date, status, event_id, created_at)
          VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
          ON CONFLICT(player_id, session_type, date) DO UPDATE SET
            status = ?,
            event_id = ?,
            created_at = CURRENT_TIMESTAMP
        `;
        await db.prepare(legacySql).bind(playerId, sessType, date, statusVal, evtIdStr, statusVal, evtIdStr).run();
        if (isPresent) recordedCount++;
      } catch (_) {
      }
    }
  }
  if (eventId) {
    try {
      await db.prepare("UPDATE events SET completion_count = ? WHERE id = ?").bind(recordedCount, eventId).run();
    } catch (e) {
      console.warn(`[API WARN] Failed to update event completion_count:`, e);
    }
  }
  console.log(`[API LOG] Recorded practice attendance for ${recordedCount} players on ${date} (${body.eventTitle || "Session"})`);
  return c.json({
    success: true,
    message: `Successfully saved attendance for ${recordedCount} players`,
    data: {
      recordedCount,
      date,
      eventId,
      sessionType: sessType
    }
  });
}, "handlePostCheckin");
app.post("/api/dashboard/checkin", handlePostCheckin);
app.post("/api/dashboard/checkins", handlePostCheckin);
app.post("/api/checkin", handlePostCheckin);
app.post("/api/checkins", handlePostCheckin);
app.get("/api/dashboard/events/:id/attendance", async (c) => {
  const eventId = c.req.param("id");
  const db = getDB(c);
  if (!db) {
    return c.json({ success: true, data: { eventId, checkedInPlayerIds: [] } });
  }
  try {
    const ev = await db.prepare("SELECT date, event_type FROM events WHERE CAST(id AS TEXT) = ? OR id = ?").bind(eventId, eventId).first();
    const targetDate = ev?.date || (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
    const { results: evtResults } = await db.prepare(`
      SELECT player_id FROM attendance WHERE (CAST(event_id AS TEXT) = ? OR event_id = ?) AND status = 'Present'
    `).bind(eventId.toString(), eventId.toString()).all();
    const checkedInPlayerIds = (evtResults || []).map((r) => r.player_id);
    return c.json({
      success: true,
      data: {
        eventId,
        date: targetDate,
        checkedInPlayerIds
      }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to fetch event attendance", error: err.message }, 500);
  }
});
var handleGetCheckins = /* @__PURE__ */ __name(async (c) => {
  const eventId = c.req.query("eventId") || c.req.query("event_id") || c.req.param("id");
  const db = getDB(c);
  if (!db) {
    return c.json({ success: true, data: [], eventId, checkedInPlayerIds: [] });
  }
  try {
    if (eventId) {
      const ev = await db.prepare("SELECT date, event_type FROM events WHERE CAST(id AS TEXT) = ? OR id = ?").bind(eventId, eventId).first();
      const targetDate = ev?.date || (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
      const { results: evtResults } = await db.prepare(`
        SELECT player_id FROM attendance WHERE (CAST(event_id AS TEXT) = ? OR event_id = ?) AND status = 'Present'
      `).bind(eventId.toString(), eventId.toString()).all();
      const checkedInPlayerIds = (evtResults || []).map((r) => r.player_id);
      const checkinArray = (evtResults || []).map((r) => ({
        eventId,
        athleteId: r.player_id,
        status: "Checked In"
      }));
      return c.json({
        success: true,
        data: checkinArray,
        eventId,
        date: targetDate,
        checkedInPlayerIds
      });
    }
    const { results } = await db.prepare("SELECT player_id, event_id, session_type, date, status, created_at FROM attendance ORDER BY created_at DESC LIMIT 100").all();
    return c.json({
      success: true,
      data: results || []
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to fetch checkins", error: err.message }, 500);
  }
}, "handleGetCheckins");
app.get("/api/checkins", handleGetCheckins);
app.get("/api/checkins/:id", handleGetCheckins);
app.get("/api/dashboard/checkins", handleGetCheckins);
app.get("/api/dashboard/checkins/:id", handleGetCheckins);
app.post("/api/match-stats", async (c) => {
  const statsInput = await c.req.json();
  const {
    playerId,
    matchDate,
    opponent,
    tacklesMade,
    tacklesMissed,
    carries,
    metresGained,
    errors,
    penalties,
    workRate,
    overallRating
  } = statsInput;
  if (!playerId || !matchDate) {
    return c.json({ success: false, message: "Player ID and Match Date are required" }, 400);
  }
  const db = getDB(c);
  const { autoScore, tacklePercentage, category } = calculateAutoScore({
    tacklesMade: tacklesMade || 0,
    tacklesMissed: tacklesMissed || 0,
    carries: carries || 0,
    metresGained: metresGained || 0,
    errors: errors || 0,
    penalties: penalties || 0,
    workRate: workRate || 0,
    overallRating: overallRating || 0
  });
  const query = `
    INSERT INTO match_stats (
      player_id, match_date, opponent, tackles_made, tackles_missed, carries, 
      metres_gained, errors, penalties, work_rate, overall_rating, auto_score, 
      tackle_percentage, category
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;
  try {
    const res = await db.prepare(query).bind(
      playerId,
      matchDate,
      opponent || "Unknown",
      tacklesMade || 0,
      tacklesMissed || 0,
      carries || 0,
      metresGained || 0,
      errors || 0,
      penalties || 0,
      workRate || 0,
      overallRating || 0,
      autoScore,
      tacklePercentage,
      category
    ).run();
    return c.json({
      success: true,
      data: {
        id: res.meta.last_row_id || null,
        playerId,
        autoScore,
        autoScorePercent: autoScore * 20,
        tacklePercentage: Math.round(tacklePercentage * 100) / 100,
        category
      }
    });
  } catch (err) {
    return c.json({ success: false, message: "Database insert failed", error: err.message }, 500);
  }
});
app.get("/api/student-portal", async (c) => {
  const authHeader = c.req.header("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return c.json({ success: false, message: "Unauthorized session" }, 401);
  }
  const token = authHeader.substring(7);
  let jwtPayload;
  try {
    jwtPayload = await verify2(token, getSecret(c), "HS256");
  } catch (err) {
    return c.json({ success: false, message: "Invalid session token" }, 401);
  }
  const userId = jwtPayload.sub;
  const role = jwtPayload.role;
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Local database not found" }, 500);
  }
  let player = null;
  const requestedPlayerId = c.req.query("player_id");
  const roleLower = (role || "").toString().toLowerCase();
  try {
    if (requestedPlayerId && requestedPlayerId.trim() !== "" && requestedPlayerId !== "null" && requestedPlayerId !== "undefined") {
      player = await db.prepare("SELECT * FROM players WHERE id = ?").bind(requestedPlayerId.trim()).first();
    }
    if (!player && (roleLower === "student" || roleLower.includes("student"))) {
      player = await db.prepare("SELECT * FROM players WHERE user_id = ?").bind(userId).first();
      if (!player) {
        const u = await db.prepare("SELECT phone, email FROM users WHERE id = ?").bind(userId).first();
        if (u && u.phone) {
          const cleanPhone = u.phone.replace(/[^\d]/g, "");
          const suffix = cleanPhone.length >= 9 ? cleanPhone.slice(-9) : cleanPhone;
          player = await db.prepare("SELECT * FROM players WHERE phone = ? OR phone LIKE ?").bind(u.phone, `%${suffix}%`).first();
        }
      }
    } else if (!player && (roleLower === "parent" || roleLower.includes("parent"))) {
      await ensureParentLinksTable(db);
      player = await db.prepare(`
        SELECT p.* FROM players p
        JOIN parent_child_links pcl ON (pcl.player_id = p.id OR pcl.player_email = (SELECT email FROM users WHERE id = p.user_id))
        WHERE pcl.parent_user_id = ? AND (pcl.status = 'accepted' OR pcl.status = 'approved' OR pcl.status IS NULL)
        ORDER BY p.first_name ASC LIMIT 1
      `).bind(userId).first();
      if (!player) {
        player = await db.prepare(`
          SELECT p.* FROM players p
          JOIN parent_child_links pcl ON (pcl.player_id = p.id OR pcl.player_email = (SELECT email FROM users WHERE id = p.user_id))
          WHERE pcl.parent_user_id = ?
          ORDER BY p.first_name ASC LIMIT 1
        `).bind(userId).first();
      }
    }
  } catch (_) {
  }
  if (!player) {
    return c.json({
      success: true,
      data: {
        profile: {
          id: "",
          firstName: "No Athlete Profile",
          lastName: "",
          team: "Unassigned",
          ageGroup: "",
          position: "--",
          schoolId: jwtPayload?.schoolId || ""
        },
        academics: [],
        fitness: {
          baseline: null,
          progressions: [],
          dynamicMetrics: [],
          readinessScore: 0
        },
        dynamicMetrics: [],
        readinessScore: 0,
        matches: [],
        attendance: [],
        events: []
      }
    });
  }
  const playerId = player.id;
  let academics = [];
  try {
    const academicsQuery = "SELECT * FROM academic_logs WHERE player_id = ? ORDER BY term ASC";
    const { results } = await db.prepare(academicsQuery).bind(playerId).all();
    academics = results || [];
  } catch (_) {
  }
  let dynamicMetrics = [];
  let totalReadinessScore = 0;
  let metricsCount = 0;
  try {
    const { results: metricDefs } = await db.prepare("SELECT * FROM test_metric_definitions WHERE school_id = ? ORDER BY category, name ASC").bind(player.school_id || "").all();
    if (metricDefs && metricDefs.length > 0) {
      for (const mDef of metricDefs) {
        const { results: logs } = await db.prepare("SELECT * FROM player_test_logs WHERE player_id = ? AND metric_id = ? ORDER BY test_date ASC").bind(playerId, mDef.id).all();
        if (logs && logs.length > 0) {
          const firstLog = logs[0];
          const latestLog = logs[logs.length - 1];
          const initialBaseline = firstLog.score;
          const latestScore = latestLog.score;
          const target = mDef.target_benchmark || latestScore;
          const goalDir = mDef.goal_direction || "HIGHER_IS_BETTER";
          let targetPercent = 100;
          if (target > 0) {
            if (goalDir === "HIGHER_IS_BETTER") {
              targetPercent = Math.min(100, Math.round(latestScore / target * 100));
            } else {
              targetPercent = Math.min(100, Math.round(target / Math.max(0.1, latestScore) * 100));
            }
          }
          let trendText = "Initial";
          if (logs.length > 1 && initialBaseline > 0) {
            const diff = latestScore - initialBaseline;
            if (goalDir === "HIGHER_IS_BETTER") {
              const pct = Math.round(diff / initialBaseline * 100);
              trendText = pct >= 0 ? `+${pct}%` : `${pct}%`;
            } else {
              const secDiff = (initialBaseline - latestScore).toFixed(1);
              trendText = parseFloat(secDiff) >= 0 ? `-${secDiff}s` : `+${Math.abs(parseFloat(secDiff))}s`;
            }
          }
          totalReadinessScore += targetPercent;
          metricsCount++;
          dynamicMetrics.push({
            id: mDef.id,
            name: mDef.name,
            category: mDef.category,
            unit: mDef.unit,
            goalDirection: goalDir,
            targetBenchmark: target,
            initialBaseline,
            latestScore,
            targetPercent,
            trendText,
            latestTestDate: latestLog.test_date,
            sessionName: latestLog.session_name,
            logsCount: logs.length
          });
        }
      }
    }
  } catch (err) {
    console.warn("Dynamic metrics fetch error:", err);
  }
  const athleteReadinessScore = metricsCount > 0 ? Math.round(totalReadinessScore / metricsCount) : 0;
  let testLogs = [];
  try {
    const { results } = await db.prepare(`
      SELECT ptl.*, tmd.name as metric_name, tmd.category as metric_category, tmd.unit as metric_unit
      FROM player_test_logs ptl
      LEFT JOIN test_metric_definitions tmd ON ptl.metric_id = tmd.id
      WHERE ptl.player_id = ?
      ORDER BY ptl.test_date DESC
    `).bind(playerId).all();
    testLogs = results || [];
  } catch (_) {
  }
  let matches = [];
  try {
    const { results } = await db.prepare("SELECT * FROM match_stats WHERE player_id = ? ORDER BY match_date DESC").bind(playerId).all();
    matches = results || [];
  } catch (_) {
  }
  let attendance = [];
  try {
    const { results } = await db.prepare('SELECT session_type, COUNT(*) as total, SUM(CASE WHEN status = "Present" THEN 1 ELSE 0 END) as present FROM attendance WHERE player_id = ? GROUP BY session_type').bind(playerId).all();
    attendance = results || [];
  } catch (_) {
  }
  let assignedSquads = [];
  try {
    const { results: sRes } = await db.prepare(`
      SELECT s.id, s.name, s.code, s.description
      FROM squads s
      JOIN squad_players sp ON sp.squad_id = s.id
      WHERE sp.player_id = ?
      ORDER BY s.name ASC
    `).bind(playerId).all();
    assignedSquads = (sRes || []).map((s) => ({
      id: s.id,
      name: s.name,
      code: s.code,
      description: s.description || ""
    }));
  } catch (_) {
  }
  if (assignedSquads.length === 0 && player.age_group) {
    assignedSquads.push({
      id: `default-${player.age_group}`,
      name: player.team || `${player.age_group} Squad`,
      code: player.age_group,
      description: ""
    });
  }
  let events = [];
  try {
    const schoolId2 = player.school_id || "";
    if (schoolId2) {
      const reqSquadId = c.req.query("squad_id") || c.req.query("squadId");
      let eventsQuery = "SELECT * FROM events WHERE school_id = ?";
      let queryParams = [schoolId2];
      if (reqSquadId && !reqSquadId.startsWith("default-")) {
        const selectedSquad = await db.prepare("SELECT name, code FROM squads WHERE id = ?").bind(reqSquadId).first();
        if (selectedSquad) {
          eventsQuery += ' AND (team = ? OR age_group = ? OR age_group IS NULL OR age_group = "")';
          queryParams.push(selectedSquad.name, selectedSquad.code);
        } else {
          eventsQuery += ' AND (age_group = ? OR age_group IS NULL OR age_group = "")';
          queryParams.push(player.age_group);
        }
      } else {
        eventsQuery += ' AND (age_group = ? OR age_group IS NULL OR age_group = "")';
        queryParams.push(player.age_group);
      }
      eventsQuery += " ORDER BY date ASC, start_time ASC";
      const { results } = await db.prepare(eventsQuery).bind(...queryParams).all();
      events = (results || []).map((r) => ({
        id: r.id?.toString() || "",
        schoolId: r.school_id,
        title: r.title,
        eventType: r.event_type,
        startTime: r.start_time,
        date: r.date,
        durationMins: r.duration_mins,
        location: r.location,
        isImportant: r.is_important === 1,
        completionCount: r.completion_count,
        ageGroup: r.age_group || null,
        team: r.team || r.age_group || null,
        workoutImagePath: r.workout_image_path
      }));
    }
  } catch (_) {
  }
  return c.json({
    success: true,
    data: {
      profile: {
        id: player.id,
        firstName: player.first_name,
        lastName: player.last_name,
        phone: player.phone || "",
        email: player.email || "",
        dob: player.dob || "",
        preferredPosition: player.preferred_position || "",
        ageGroup: player.age_group,
        position: player.position,
        team: player.team,
        grade: player.grade,
        age: player.age,
        notes: player.notes,
        assignedSquads
      },
      academics: academics.map((a) => ({
        id: a.id,
        term: a.term,
        gradePercentage: a.grade_percentage,
        disciplineScore: a.discipline_score
      })),
      fitness: {
        readinessScore: athleteReadinessScore,
        dynamicMetrics,
        testLogs: testLogs.map((tl) => ({
          id: tl.id,
          metricId: tl.metric_id,
          metricName: tl.metric_name || tl.test_name || tl.metric_id,
          score: tl.score !== void 0 && tl.score !== null ? tl.score : tl.score_value,
          unit: tl.metric_unit || tl.unit || "",
          category: tl.metric_category || tl.category || "General",
          testDate: tl.test_date,
          sessionName: tl.session_name || "Evaluation",
          notes: tl.notes || ""
        })),
        baseline: null,
        progressions: []
      },
      matches: matches.map((m) => ({
        id: m.id,
        matchDate: m.match_date,
        opponent: m.opponent,
        tacklesMade: m.tackles_made,
        tacklesMissed: m.tackles_missed,
        carries: m.carries,
        metresGained: m.metres_gained,
        errors: m.errors,
        penalties: m.penalties,
        workRate: m.work_rate,
        overallRating: m.overall_rating,
        autoScore: m.auto_score,
        tacklePercentage: m.tackle_percentage,
        category: m.category
      })),
      attendance: attendance.map((a) => ({
        sessionType: a.session_type,
        total: a.total,
        present: a.present || 0
      })),
      events
    }
  });
});
app.post("/api/student-portal/profile", async (c) => {
  const db = getDB(c);
  let userId = "";
  const authHeader = c.req.header("Authorization");
  if (authHeader && authHeader.startsWith("Bearer ")) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify2(token, getSecret(c), "HS256");
      if (payload && payload.sub) {
        userId = payload.sub;
      }
    } catch (_) {
    }
  }
  if (!userId) {
    return c.json({ success: false, message: "Unauthorized session" }, 401);
  }
  try {
    const body = await c.req.json();
    const { firstName, lastName, phone, email, dob, preferredPosition, playerId: reqPlayerId } = body;
    let targetPlayer = null;
    if (reqPlayerId) {
      targetPlayer = await db.prepare("SELECT * FROM players WHERE id = ?").bind(reqPlayerId).first();
    }
    if (!targetPlayer) {
      targetPlayer = await db.prepare("SELECT * FROM players WHERE user_id = ? OR id = ?").bind(userId, userId).first();
    }
    if (!targetPlayer) {
      const u = await db.prepare("SELECT phone, email FROM users WHERE id = ?").bind(userId).first();
      if (u && u.phone) {
        const cleanPhone = u.phone.replace(/[^\d]/g, "");
        const suffix = cleanPhone.length >= 9 ? cleanPhone.slice(-9) : cleanPhone;
        targetPlayer = await db.prepare("SELECT * FROM players WHERE phone = ? OR phone LIKE ?").bind(u.phone, `%${suffix}%`).first();
      }
    }
    if (!targetPlayer) {
      targetPlayer = await db.prepare("SELECT * FROM players ORDER BY first_name ASC LIMIT 1").first();
    }
    if (!targetPlayer) {
      return c.json({ success: false, message: "Player record not found" }, 404);
    }
    let formattedPhone = phone;
    if (phone && phone.trim().length > 0) {
      let clean = phone.replace(/[^\d+]/g, "");
      if (clean.startsWith("0")) {
        clean = "+27" + clean.slice(1);
      } else if (!clean.startsWith("+")) {
        clean = "+27" + clean;
      }
      formattedPhone = clean;
    }
    await db.prepare(`
      UPDATE players
      SET first_name = COALESCE(?, first_name),
          last_name = COALESCE(?, last_name),
          phone = COALESCE(?, phone),
          dob = COALESCE(?, dob),
          preferred_position = COALESCE(?, preferred_position),
          user_id = COALESCE(user_id, ?)
      WHERE id = ?
    `).bind(
      firstName || null,
      lastName || null,
      formattedPhone || null,
      dob || null,
      preferredPosition || null,
      userId,
      targetPlayer.id
    ).run();
    if (email && email.trim()) {
      const cleanEmail = email.trim().toLowerCase();
      const targetUserId = targetPlayer.user_id || userId;
      try {
        await db.prepare("UPDATE users SET email = ? WHERE id = ?").bind(cleanEmail, targetUserId).run();
      } catch (_) {
      }
    }
    return c.json({ success: true, message: "Profile updated successfully", phone: formattedPhone, playerId: targetPlayer.id });
  } catch (err) {
    console.error("[API Error] Profile save error:", err);
    return c.json({ success: false, message: "Failed to update profile", error: err.message }, 500);
  }
});
app.post("/api/player/evaluation-baseline", async (c) => {
  const db = getDB(c);
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const { playerId, metricId, score, testDate, sessionName, notes } = body;
  if (!playerId || !metricId || score === void 0 || score === null) {
    return c.json({ success: false, message: "playerId, metricId, and score are required" }, 400);
  }
  const dateStr = testDate || (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
  try {
    const existing = await db.prepare("SELECT id FROM player_test_logs WHERE player_id = ? AND metric_id = ? AND test_date = ?").bind(playerId, metricId, dateStr).first();
    const targetId = existing?.id || `ptl_${playerId}_${metricId}_${dateStr}`.replace(/[^a-zA-Z0-9_-]/g, "_");
    await db.prepare(`
      INSERT INTO player_test_logs (id, player_id, metric_id, score, test_date, session_name, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        score = excluded.score,
        session_name = excluded.session_name,
        notes = excluded.notes
    `).bind(
      targetId,
      playerId,
      metricId,
      parseFloat(score.toString()),
      dateStr,
      sessionName || "Baseline Evaluation",
      notes || null
    ).run();
    return c.json({
      success: true,
      message: "Evaluation baseline updated successfully",
      data: { id: targetId, playerId, metricId, score, testDate: dateStr }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to update evaluation baseline", error: err.message }, 500);
  }
});
app.get("/api/test-metrics", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const schoolId2 = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query("school_id") || c.req.query("schoolId") || "1";
  const db = getDB(c);
  try {
    let { results } = await db.prepare("SELECT * FROM test_metric_definitions WHERE school_id = ? OR CAST(school_id AS TEXT) = CAST(? AS TEXT) ORDER BY category, name ASC").bind(schoolId2, schoolId2).all();
    if (!results || results.length === 0) {
      const fallback = await db.prepare("SELECT * FROM test_metric_definitions ORDER BY category, name ASC").all();
      results = fallback.results || [];
    }
    return c.json({
      success: true,
      data: (results || []).map((m) => ({
        id: m.id,
        schoolId: m.school_id,
        name: m.name,
        category: m.category,
        unit: m.unit,
        goalDirection: m.goal_direction,
        targetBenchmark: m.target_benchmark
      }))
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to fetch test metrics", error: err.message }, 500);
  }
});
app.post("/api/test-metrics", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const db = getDB(c);
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const schoolId2 = jwtPayload?.schoolId || jwtPayload?.school_id || body?.schoolId || body?.school_id || c.req.query("school_id") || c.req.query("schoolId") || "1";
  const { id, name, category, unit, goalDirection, targetBenchmark } = body || {};
  const metricName = (name || body?.metricName || body?.title || "").trim();
  const metricUnit = (unit || body?.metricUnit || body?.u || "units").trim();
  if (!metricName) {
    return c.json({ success: false, message: "Metric name is required." }, 400);
  }
  const catName = category && category.trim() ? category.trim() : "General";
  const metricId = id || generatePrimaryKey("tm");
  try {
    await db.prepare(`
      INSERT INTO test_metric_definitions (id, school_id, name, category, unit, goal_direction, target_benchmark)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        category = excluded.category,
        unit = excluded.unit,
        goal_direction = excluded.goal_direction,
        target_benchmark = excluded.target_benchmark
    `).bind(
      metricId,
      schoolId2,
      metricName,
      catName,
      metricUnit,
      goalDirection || "HIGHER_IS_BETTER",
      targetBenchmark || 0
    ).run();
    console.log(`[Observer Log] Test metric '${metricId}' (${metricName}) saved for school '${schoolId2}'.`);
    return c.json({
      success: true,
      message: "Test metric saved successfully",
      data: { id: metricId, schoolId: schoolId2, name: metricName, category: catName, unit: metricUnit, goalDirection: goalDirection || "HIGHER_IS_BETTER", targetBenchmark: targetBenchmark || 0 }
    });
  } catch (err) {
    console.error(`[Observer Error] Failed to save test metric: ${err.message}`);
    return c.json({ success: false, message: "Failed to save test metric", error: err.message }, 500);
  }
});
app.delete("/api/test-metrics/:id", async (c) => {
  const metricId = c.req.param("id");
  const db = getDB(c);
  try {
    await db.prepare("DELETE FROM test_metric_definitions WHERE id = ? OR name = ?").bind(metricId, metricId).run();
    console.log(`[Observer Log] Test metric '${metricId}' deleted.`);
    return c.json({ success: true, message: "Test metric deleted successfully" });
  } catch (err) {
    console.error(`[Observer Error] Failed to delete test metric: ${err.message}`);
    return c.json({ success: false, message: "Failed to delete test metric", error: err.message }, 500);
  }
});
app.get("/api/dashboard/test-metrics", async (c) => {
  const url = new URL(c.req.url);
  url.pathname = "/api/test-metrics";
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.post("/api/dashboard/test-metrics", async (c) => {
  const url = new URL(c.req.url);
  url.pathname = "/api/test-metrics";
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.delete("/api/dashboard/test-metrics/:id", async (c) => {
  const metricId = c.req.param("id");
  const url = new URL(c.req.url);
  url.pathname = `/api/test-metrics/${metricId}`;
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.post("/api/dashboard/test-logs/batch", async (c) => {
  const url = new URL(c.req.url);
  url.pathname = "/api/test-logs/batch";
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.post("/api/dashboard/test-logs", async (c) => {
  const url = new URL(c.req.url);
  url.pathname = "/api/test-logs/batch";
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.post("/api/test-logs", async (c) => {
  const url = new URL(c.req.url);
  url.pathname = "/api/test-logs/batch";
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.post("/api/test-logs/batch", async (c) => {
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Database connection unavailable" }, 500);
  }
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const logs = body.logs || body.scores || body.data;
  const metricId = body.metricId || body.metric_id || (Array.isArray(logs) && logs.length > 0 ? logs[0].metricId || logs[0].metric_id : null);
  const testDate = body.testDate || body.test_date || body.date || (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
  const sessionName = body.sessionName || body.session_name || body.eventTitle || "Evaluation";
  const eventId = body.eventId || body.event_id || (Array.isArray(logs) && logs.length > 0 ? logs[0].eventId : null);
  if (!Array.isArray(logs) || logs.length === 0) {
    return c.json({ success: false, message: "A non-empty logs array is required" }, 400);
  }
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS player_test_logs (
        id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL,
        metric_id TEXT NOT NULL,
        score REAL NOT NULL,
        test_date TEXT NOT NULL,
        session_name TEXT DEFAULT 'Evaluation',
        event_id TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `).run().catch(() => {
    });
    await db.prepare("ALTER TABLE player_test_logs ADD COLUMN notes TEXT").run().catch(() => {
    });
    await db.prepare("ALTER TABLE player_test_logs ADD COLUMN session_name TEXT").run().catch(() => {
    });
    await db.prepare("ALTER TABLE player_test_logs ADD COLUMN event_id TEXT").run().catch(() => {
    });
    let savedCount = 0;
    for (const item of logs) {
      const pId = item.playerId || item.player_id || item.id;
      if (!pId || item.score === void 0 || item.score === null || item.score === "") continue;
      const scoreVal = parseFloat(item.score.toString());
      if (isNaN(scoreVal)) continue;
      const targetMetricId = item.metricId || item.metric_id || metricId;
      if (!targetMetricId) continue;
      const fallbackId = `ptl_${Date.now()}_${pId}_${targetMetricId}_${testDate}`.replace(/[^a-zA-Z0-9_-]/g, "_");
      try {
        const existing = await db.prepare("SELECT id FROM player_test_logs WHERE player_id = ? AND metric_id = ? AND test_date = ?").bind(pId, targetMetricId, testDate).first();
        const targetId = existing?.id || item.id || fallbackId;
        await db.prepare(`
          INSERT INTO player_test_logs (id, player_id, metric_id, score, test_date, session_name, event_id, notes)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            score = excluded.score,
            session_name = excluded.session_name,
            event_id = excluded.event_id,
            notes = excluded.notes
        `).bind(
          targetId,
          pId,
          targetMetricId,
          scoreVal,
          testDate,
          sessionName,
          eventId || null,
          item.notes || null
        ).run();
        savedCount++;
      } catch (e) {
        console.warn(`Failed test log insert for player ${pId}:`, e);
      }
    }
    return c.json({
      success: true,
      message: `Saved ${savedCount} test log(s) successfully`,
      data: { savedCount, metricId, testDate }
    });
  } catch (err) {
    console.error("[Observer Error] Failed to batch log test scores:", err);
    return c.json({ success: false, message: "Failed to save test scores", error: err.message }, 500);
  }
});
app.get("/api/admin/all-players", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const db = getDB(c);
  const schoolId2 = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query("school_id") || c.req.query("schoolId") || "1";
  try {
    const sId = String(schoolId2);
    const query = "SELECT id, first_name, last_name, age_group, team, position FROM players WHERE (school_id = ? OR CAST(school_id AS TEXT) = ?) ORDER BY age_group, team, last_name, first_name";
    let { results } = await db.prepare(query).bind(sId, sId).all();
    if (!results || results.length === 0) {
      const fallbackRes = await db.prepare("SELECT id, first_name, last_name, age_group, team, position FROM players ORDER BY age_group, team, last_name, first_name").all();
      results = fallbackRes.results || [];
    }
    return c.json({
      success: true,
      data: (results || []).map((r) => ({
        id: r.id,
        firstName: r.first_name,
        lastName: r.last_name,
        ageGroup: r.age_group,
        team: r.team,
        position: r.position
      }))
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to retrieve players", error: err.message }, 500);
  }
});
app.get("/api/school/players", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const searchQuery = (c.req.query("q") || c.req.query("query") || "").trim();
  const db = getDB(c);
  await ensureSquadsTables(db);
  try {
    let sql = "SELECT id, first_name, last_name, age_group, team, position, status FROM players WHERE 1=1";
    let params = [];
    if (searchQuery) {
      sql += ' AND (first_name LIKE ? OR last_name LIKE ? OR (first_name || " " || last_name) LIKE ?)';
      const term = `%${searchQuery}%`;
      params.push(term, term, term);
    }
    sql += " ORDER BY last_name ASC, first_name ASC LIMIT 100";
    const { results } = await db.prepare(sql).bind(...params).all();
    const players = results || [];
    if (players.length > 0) {
      const pIds = players.map((p) => p.id);
      const placeholders = pIds.map(() => "?").join(",");
      const { results: sqRes } = await db.prepare(`
        SELECT sp.player_id, s.id as squad_id, s.name as squad_name, s.code as squad_code
        FROM squad_players sp
        JOIN squads s ON s.id = sp.squad_id
        WHERE sp.player_id IN (${placeholders})
      `).bind(...pIds).all();
      const sqMap = {};
      for (const row of sqRes || []) {
        if (!sqMap[row.player_id]) sqMap[row.player_id] = [];
        sqMap[row.player_id].push({
          id: row.squad_id,
          name: row.squad_name,
          code: row.squad_code
        });
      }
      for (const p of players) {
        p.assignedSquads = sqMap[p.id] || [];
      }
    }
    return c.json({
      success: true,
      data: players.map((p) => ({
        id: p.id,
        firstName: p.first_name,
        lastName: p.last_name,
        ageGroup: p.age_group,
        team: p.team || p.age_group,
        position: p.position,
        status: p.status || "",
        assignedSquads: p.assignedSquads || []
      }))
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to retrieve players", error: err.message }, 500);
  }
});
app.post("/api/squads/:squadId/players/add", async (c) => {
  const squadId = c.req.param("squadId");
  const body = await c.req.json();
  const playerId = body.playerId;
  const db = getDB(c);
  if (!playerId) {
    return c.json({ success: false, message: "playerId is required" }, 400);
  }
  await ensureSquadsTables(db);
  try {
    await db.prepare("INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)").bind(squadId, playerId).run();
    let squad = null;
    try {
      squad = await db.prepare("SELECT id, code, name FROM squads WHERE id = ? OR code = ? OR name = ?").bind(squadId, squadId, squadId).first();
    } catch (_) {
    }
    if (squad) {
      await db.prepare("INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)").bind(squad.id, playerId).run();
      await db.prepare("INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)").bind(squad.code, playerId).run();
      await db.prepare(`
        UPDATE players
        SET age_group = CASE WHEN age_group IS NULL OR age_group = 'Unassigned' OR age_group = '' THEN ? ELSE age_group END,
            team = CASE WHEN team IS NULL OR team = 'Unassigned' OR team = '' THEN ? ELSE team END
        WHERE id = ?
      `).bind(squad.code, squad.name, playerId).run();
    } else {
      await db.prepare(`
        UPDATE players
        SET age_group = CASE WHEN age_group IS NULL OR age_group = 'Unassigned' OR age_group = '' THEN ? ELSE age_group END,
            team = CASE WHEN team IS NULL OR team = 'Unassigned' OR team = '' THEN ? ELSE team END
        WHERE id = ?
      `).bind(squadId, squadId, playerId).run();
    }
    console.log(`[Observer Log] Added player '${playerId}' to squad '${squadId}'`);
    return c.json({
      success: true,
      message: "Player added to squad successfully",
      data: { squadId, playerId }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to add player to squad", error: err.message }, 500);
  }
});
app.post("/api/squads/:squadId/players/remove", async (c) => {
  const squadId = c.req.param("squadId");
  const body = await c.req.json();
  const playerId = body.playerId;
  const db = getDB(c);
  if (!playerId) {
    return c.json({ success: false, message: "playerId is required" }, 400);
  }
  await ensureSquadsTables(db);
  try {
    let squad = null;
    try {
      squad = await db.prepare("SELECT id, code, name FROM squads WHERE id = ? OR code = ? OR name = ?").bind(squadId, squadId, squadId).first();
    } catch (_) {
    }
    const targetSquadKeys = Array.from(/* @__PURE__ */ new Set([squadId, ...squad ? [squad.id, squad.code, squad.name] : []]));
    const ph = targetSquadKeys.map(() => "?").join(",");
    await db.prepare(`DELETE FROM squad_players WHERE player_id = ? AND squad_id IN (${ph})`).bind(playerId, ...targetSquadKeys).run();
    await db.prepare(`
      UPDATE players
      SET age_group = CASE WHEN age_group IN (${ph}) THEN 'Unassigned' ELSE age_group END,
          team = CASE WHEN team IN (${ph}) THEN NULL ELSE team END
      WHERE id = ?
    `).bind(...targetSquadKeys, ...targetSquadKeys, playerId).run();
    console.log(`[Observer Log] Removed player '${playerId}' from squad '${squadId}'`);
    return c.json({
      success: true,
      message: "Player removed from squad successfully",
      data: { squadId, playerId }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to remove player from squad", error: err.message }, 500);
  }
});
var handleAddSquadMember = /* @__PURE__ */ __name(async (c) => {
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Database connection unavailable" }, 500);
  }
  let body = {};
  try {
    body = await c.req.json();
  } catch (_) {
  }
  const { squadId, squadName, athleteId, playerId } = body;
  const targetPlayerId = athleteId || playerId;
  const targetSquadId = squadId || squadName;
  if (!targetSquadId || !targetPlayerId) {
    return c.json({ success: false, message: "squadId/squadName and athleteId/playerId are required" }, 400);
  }
  await ensureSquadsTables(db);
  try {
    await db.prepare("INSERT INTO squad_players (squad_id, player_id) VALUES (?, ?) ON CONFLICT DO NOTHING").bind(targetSquadId, targetPlayerId).run();
    await db.prepare("UPDATE players SET team = ? WHERE id = ?").bind(targetSquadId, targetPlayerId).run();
    return c.json({
      success: true,
      message: "Member added to squad"
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to add member to squad", error: err.message }, 500);
  }
}, "handleAddSquadMember");
var handleRemoveSquadMember = /* @__PURE__ */ __name(async (c) => {
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: "Database connection unavailable" }, 500);
  }
  let body = {};
  try {
    body = await c.req.json();
  } catch (_) {
  }
  const { squadId, athleteId, playerId } = body;
  const targetPlayerId = athleteId || playerId;
  const targetSquadId = squadId;
  if (!targetSquadId || !targetPlayerId) {
    return c.json({ success: false, message: "squadId and athleteId/playerId are required" }, 400);
  }
  await ensureSquadsTables(db);
  try {
    await db.prepare("DELETE FROM squad_players WHERE squad_id = ? AND player_id = ?").bind(targetSquadId, targetPlayerId).run();
    await db.prepare("UPDATE players SET team = NULL WHERE id = ? AND team = ?").bind(targetPlayerId, targetSquadId).run();
    return c.json({
      success: true,
      message: "Member removed from squad"
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to remove member from squad", error: err.message }, 500);
  }
}, "handleRemoveSquadMember");
app.post("/api/squads/members", handleAddSquadMember);
app.post("/api/dashboard/squads/members", handleAddSquadMember);
app.delete("/api/squads/members", handleRemoveSquadMember);
app.delete("/api/dashboard/squads/members", handleRemoveSquadMember);
app.post("/api/squads/members/delete", handleRemoveSquadMember);
app.post("/api/dashboard/squads/members/delete", handleRemoveSquadMember);
app.post("/api/upload", async (c) => {
  try {
    const body = await c.req.json();
    const { imageBase64, filename } = body;
    if (!imageBase64) {
      return c.json({ success: false, message: "Image data is required" }, 400);
    }
    const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, "");
    const binaryData = Uint8Array.from(atob(base64Data), (c2) => c2.charCodeAt(0));
    const key = `uploads/${Date.now()}-${filename || "avatar.jpg"}`;
    if (c.env.R2) {
      await c.env.R2.put(key, binaryData, {
        httpMetadata: { contentType: "image/jpeg" }
      });
      const publicUrl = `https://academypro-assets.tata-elash34.workers.dev/${key}`;
      return c.json({ success: true, url: publicUrl, message: "Image uploaded successfully" });
    }
    const dataUrl = `data:image/jpeg;base64,${base64Data}`;
    return c.json({ success: true, url: dataUrl, message: "Image processed successfully" });
  } catch (err) {
    return c.json({ success: false, message: "Upload failed", error: err.message }, 500);
  }
});
app.post("/api/admin/bulk-upload", async (c) => {
  const db = getDB(c);
  let payload;
  try {
    payload = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const { records } = payload;
  if (!records || !Array.isArray(records)) {
    return c.json({ success: false, message: "Invalid records array" }, 400);
  }
  let successCount = 0;
  let errorCount = 0;
  const errors = [];
  for (const record of records) {
    const { id, vertical, dash40yd, gpa } = record;
    if (!id) {
      errorCount++;
      errors.push("Missing athlete ID");
      continue;
    }
    const player_id = id.trim().startsWith("#") ? id.trim().substring(1) : id.trim();
    try {
      const playerExists = await db.prepare("SELECT id FROM players WHERE id = ?").bind(player_id).first();
      if (!playerExists) {
        errorCount++;
        errors.push(`Athlete ID ${player_id} does not exist in roster`);
        continue;
      }
      const todayStr = (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
      const vertValue = vertical !== void 0 && vertical !== null && vertical !== "" ? parseFloat(vertical) : null;
      const dashValue = dash40yd !== void 0 && dash40yd !== null && dash40yd !== "" ? parseFloat(dash40yd) : null;
      if (vertValue !== null && !isNaN(vertValue)) {
        const vertMetricId = "metric_vertical_jump";
        const vertLogId = `ptl_${player_id}_vert_${todayStr}`;
        await db.prepare(`
          INSERT INTO player_test_logs (id, player_id, metric_id, score, test_date, session_name, notes)
          VALUES (?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            score = excluded.score,
            session_name = excluded.session_name,
            notes = excluded.notes
        `).bind(vertLogId, player_id, vertMetricId, vertValue, todayStr, "Bulk Upload Baseline", "Vertical Jump (cm)").run();
      }
      if (dashValue !== null && !isNaN(dashValue)) {
        const dashMetricId = "metric_speed_40m";
        const dashLogId = `ptl_${player_id}_dash_${todayStr}`;
        await db.prepare(`
          INSERT INTO player_test_logs (id, player_id, metric_id, score, test_date, session_name, notes)
          VALUES (?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            score = excluded.score,
            session_name = excluded.session_name,
            notes = excluded.notes
        `).bind(dashLogId, player_id, dashMetricId, dashValue, todayStr, "Bulk Upload Baseline", "40m Speed Dash (s)").run();
      }
      const sqlAcademic = `
        INSERT INTO academic_logs (player_id, term, grade_percentage, created_at)
        VALUES (?, 1, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(player_id, term) DO UPDATE SET
          grade_percentage = excluded.grade_percentage
      `;
      let gradePercentage = gpa !== void 0 && gpa !== null && gpa !== "" ? parseFloat(gpa) : null;
      if (gradePercentage !== null && gradePercentage <= 5) {
        gradePercentage = gradePercentage / 4 * 100;
      }
      await db.prepare(sqlAcademic).bind(player_id, gradePercentage).run();
      successCount++;
    } catch (err) {
      errorCount++;
      errors.push(`Failed to update ${player_id}: ${err.message}`);
    }
  }
  const statusCode = errorCount === 0 ? 200 : successCount > 0 ? 207 : 400;
  return c.json({
    success: errorCount === 0,
    message: `Bulk upload completed. Success: ${successCount}, Errors: ${errorCount}`,
    data: {
      successCount,
      errorCount,
      errors
    }
  }, statusCode);
});
app.get("/api/admin/sports-config", async (c) => {
  const db = getDB(c);
  const defaultConfig = [
    {
      id: "rugby",
      name: "Rugby",
      config: {
        fields: [
          { key: "tackles_made", label: "Tackles Made", type: "counter" },
          { key: "carries", label: "Ball Carries", type: "counter" },
          { key: "metres_gained", label: "Metres Gained", type: "numeric" },
          { key: "turnovers_won", label: "Turnovers Won", type: "counter" },
          { key: "passes", label: "Passes Completed", type: "counter" }
        ]
      }
    }
  ];
  try {
    const { results } = await db.prepare("SELECT id, name, config_json FROM sports").all();
    if (results && results.length > 0) {
      return c.json({
        success: true,
        data: results.map((r) => ({
          id: r.id,
          name: r.name,
          config: typeof r.config_json === "string" ? JSON.parse(r.config_json) : r.config_json || {}
        }))
      });
    }
  } catch (err) {
    console.warn(`[API WARN] Failed to query sports table:`, err);
  }
  return c.json({
    success: true,
    data: defaultConfig
  });
});
app.post("/api/players/:id/position", async (c) => {
  const playerId = c.req.param("id");
  const body = await c.req.json();
  const position = body.position;
  const db = getDB(c);
  if (position === void 0 || position === null) {
    return c.json({ success: false, message: "Position is required" }, 400);
  }
  try {
    const query = "UPDATE players SET position = ? WHERE id = ?";
    await db.prepare(query).bind(position, playerId).run();
    console.log(`[Observer Log] Updated position to '${position}' for player '${playerId}'`);
    return c.json({
      success: true,
      message: "Player position updated successfully"
    });
  } catch (err) {
    return c.json({
      success: false,
      message: "Failed to update player position",
      error: err.message
    }, 500);
  }
});
app.post("/api/players", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const body = await c.req.json();
  const schoolId2 = jwtPayload?.schoolId || jwtPayload?.school_id || body.schoolId || c.req.query("school_id") || c.req.query("schoolId") || 1;
  const { id, firstName, lastName, ageGroup, position, team, email, squadId } = body;
  const db = getDB(c);
  if (!firstName || !lastName || !ageGroup) {
    return c.json({ success: false, message: "First name, last name, and age group are required" }, 400);
  }
  const playerId = id || `PL-${Date.now().toString().substring(7)}`;
  const playerEmail = email && email.trim() ? email.trim().toLowerCase() : `${firstName.toLowerCase().replace(/\s+/g, "")}.${lastName.toLowerCase().replace(/\s+/g, "")}@academypro.co.za`;
  try {
    await db.prepare(`
      INSERT OR REPLACE INTO players (id, school_id, first_name, last_name, age_group, position, team, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'Active')
    `).bind(playerId, schoolId2, firstName, lastName, ageGroup, position || "Athlete", team || `${ageGroup} Squad`).run();
    const existingUser = await db.prepare("SELECT id FROM users WHERE email = ?").bind(playerEmail).first();
    let userId = existingUser?.id;
    if (!existingUser) {
      userId = `USR-PL-${Date.now().toString().substring(6)}`;
      await db.prepare(`
        INSERT INTO users (id, email, first_name, last_name, role, school_id, password_hash)
        VALUES (?, ?, ?, ?, 'Player', ?, 'PENDING_ACTIVATION')
      `).bind(userId, playerEmail, firstName, lastName, schoolId2).run();
    }
    try {
      await db.prepare("UPDATE players SET user_id = ? WHERE id = ?").bind(userId, playerId).run();
    } catch (_) {
    }
    if (squadId) {
      try {
        await db.prepare(
          "INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)"
        ).bind(squadId, playerId).run();
      } catch (_) {
      }
    }
    if (jwtPayload && jwtPayload.sub) {
      try {
        const squad = await db.prepare(
          "SELECT id FROM squads WHERE coach_id = ? AND school_id = ? AND (code = ? OR name = ?)"
        ).bind(jwtPayload.sub, schoolId2, ageGroup, team || ageGroup).first();
        if (squad) {
          await db.prepare(
            "INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)"
          ).bind(squad.id, playerId).run();
        }
      } catch (_) {
      }
    }
    const inviteHtml = `<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; background-color: #FAF8FF; color: #131B2E; margin: 0; padding: 20px; }
    .container { max-width: 520px; background-color: #ffffff; border: 1px solid #E2E8F0; border-radius: 16px; padding: 32px; margin: 0 auto; }
    .header { text-align: center; margin-bottom: 24px; }
    .title { font-size: 26px; font-weight: 900; color: #003EC7; margin: 0; }
    .content { font-size: 15px; line-height: 1.6; color: #434656; }
    .btn { display: inline-block; background-color: #003EC7; color: #ffffff !important; padding: 14px 28px; border-radius: 12px; font-weight: bold; text-decoration: none; margin: 20px 0; }
    .footer { text-align: center; font-size: 12px; color: #737688; margin-top: 32px; border-top: 1px solid #E2E8F0; padding-top: 16px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 class="title">AcademyPro</h1>
    </div>
    <div class="content">
      <p>Hi <strong>${firstName} ${lastName}</strong>,</p>
      <p>You have been enrolled in the <strong>${team || ageGroup}</strong> squad on AcademyPro High Performance Athlete Hub!</p>
      <p>Log in with your email address (<strong>${playerEmail}</strong>) to access your training schedule, performance stats, attendance QR code, and coach feedback.</p>
      <div style="text-align: center;">
        <a href="https://academypro-app.web.app/invite?email=${encodeURIComponent(playerEmail)}" class="btn">Activate Account & Open App</a>
      </div>
    </div>
    <div class="footer">
      <p>\xA9 2026 CodeWays PTY Ltd. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`;
    await sendTransactionalEmail(c, {
      to: playerEmail,
      fromName: "AcademyPro Sports",
      fromEmail: "noreply@web.codeways.co",
      subject: `Welcome to AcademyPro \u2014 ${team} Squad Invitation`,
      htmlContent: inviteHtml,
      textContent: `Hi ${firstName},

You have been added to the ${team} squad on AcademyPro. Log in with ${playerEmail} to view your training schedule and stats.`
    });
    console.log(`[Observer Log] Created player ${playerId} (${firstName} ${lastName}) and sent email invite to ${playerEmail}`);
    return c.json({
      success: true,
      message: "Player created and email invitation sent successfully",
      data: { id: playerId, email: playerEmail }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to create player", error: err.message }, 500);
  }
});
async function ensureParentLinksTable(db) {
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS parent_child_links (
        id TEXT PRIMARY KEY,
        parent_user_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        player_email TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `).run();
  } catch (err) {
    console.warn("Failed to ensure parent_child_links table:", err);
  }
}
__name(ensureParentLinksTable, "ensureParentLinksTable");
app.post("/api/parent/link-request", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const parentUserId = jwtPayload?.sub;
  if (!parentUserId) {
    return c.json({ success: false, message: "Unauthorized session" }, 401);
  }
  let body;
  try {
    body = await c.req.json();
  } catch (_) {
    return c.json({ success: false, message: "Invalid payload" }, 400);
  }
  const { childEmail } = body;
  const db = getDB(c);
  if (!childEmail || !childEmail.trim()) {
    return c.json({ success: false, message: "Child email address is required" }, 400);
  }
  const cleanChildEmail = childEmail.trim().toLowerCase();
  await ensureParentLinksTable(db);
  try {
    let player = await db.prepare('SELECT id, first_name, last_name, user_id FROM players WHERE LOWER(first_name || "." || last_name || "@academypro.co.za") = ? LIMIT 1').bind(cleanChildEmail).first();
    if (!player) {
      const user = await db.prepare("SELECT id, first_name, last_name FROM users WHERE email = ?").bind(cleanChildEmail).first();
      if (user) {
        player = await db.prepare("SELECT id, first_name, last_name, user_id FROM players WHERE user_id = ?").bind(user.id).first();
      }
    }
    if (!player) {
      return c.json({ success: false, message: "No registered athlete profile found for provided child email" }, 404);
    }
    const playerId = player.id;
    const existing = await db.prepare("SELECT id, status FROM parent_child_links WHERE parent_user_id = ? AND player_email = ?").bind(parentUserId, cleanChildEmail).first();
    if (existing) {
      return c.json({
        success: true,
        message: `Link request already exists with status: ${existing.status}`,
        data: { id: existing.id, status: existing.status }
      });
    }
    const linkId = `LINK-${Date.now().toString().substring(6)}`;
    await db.prepare(`
      INSERT INTO parent_child_links (id, parent_user_id, player_id, player_email, status)
      VALUES (?, ?, ?, ?, 'pending')
    `).bind(linkId, parentUserId, playerId, cleanChildEmail).run();
    if (player.user_id) {
      try {
        await db.prepare(`
          INSERT INTO notifications (user_id, title, body, type, is_read, created_at)
          VALUES (?, 'Parent Link Request', 'A parent has requested to link to your athlete profile. Tap to review and accept.', 'link_request', 0, CURRENT_TIMESTAMP)
        `).bind(player.user_id).run();
      } catch (_) {
      }
    }
    return c.json({
      success: true,
      message: "Parent link request sent successfully. Waiting for player approval.",
      data: { id: linkId, status: "pending" }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to send link request", error: err.message }, 500);
  }
});
app.get("/api/player/link-requests", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const userId = jwtPayload?.sub;
  if (!userId) {
    return c.json({ success: false, message: "Unauthorized session" }, 401);
  }
  const db = getDB(c);
  await ensureParentLinksTable(db);
  try {
    const user = await db.prepare("SELECT email FROM users WHERE id = ?").bind(userId).first();
    const userEmail = user?.email || "player@academypro.co.za";
    const { results } = await db.prepare(`
      SELECT pcl.id, pcl.status, pcl.created_at, u.first_name as parent_first_name, u.last_name as parent_last_name, u.email as parent_user_email
      FROM parent_child_links pcl
      LEFT JOIN users u ON pcl.parent_user_id = u.id
      WHERE pcl.player_email = ? OR pcl.player_id IN (SELECT id FROM players WHERE user_id = ?)
    `).bind(userEmail, userId).all();
    return c.json({
      success: true,
      data: (results || []).map((r) => ({
        id: r.id,
        parentName: `${r.parent_first_name || "Parent"} ${r.parent_last_name || ""}`.trim(),
        parentEmail: r.parent_user_email || r.email || "",
        status: r.status,
        createdAt: r.created_at
      }))
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to fetch link requests", error: err.message }, 500);
  }
});
app.post("/api/player/link-requests/:id/respond", async (c) => {
  const linkId = c.req.param("id");
  const { action } = await c.req.json();
  const db = getDB(c);
  await ensureParentLinksTable(db);
  if (!action || action !== "accept" && action !== "reject") {
    return c.json({ success: false, message: "Action must be accept or reject" }, 400);
  }
  const newStatus = action === "accept" ? "accepted" : "rejected";
  try {
    await db.prepare("UPDATE parent_child_links SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?").bind(newStatus, linkId).run();
    return c.json({
      success: true,
      message: `Parent link request ${newStatus} successfully`,
      data: { id: linkId, status: newStatus }
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to respond to link request", error: err.message }, 500);
  }
});
app.get("/api/parent/children", async (c) => {
  const jwtPayload = c.get("jwtPayload");
  const parentUserId = jwtPayload?.sub;
  if (!parentUserId) {
    return c.json({ success: false, message: "Unauthorized session" }, 401);
  }
  const db = getDB(c);
  await ensureParentLinksTable(db);
  try {
    const { results } = await db.prepare(`
      SELECT p.*, pcl.status as link_status
      FROM parent_child_links pcl
      JOIN players p ON pcl.player_id = p.id OR pcl.player_email = (SELECT email FROM users WHERE id = p.user_id)
      WHERE pcl.parent_user_id = ? AND pcl.status = 'accepted'
    `).bind(parentUserId).all();
    const children = results || [];
    return c.json({
      success: true,
      data: children.map((p) => ({
        id: p.id,
        firstName: p.first_name,
        lastName: p.last_name,
        ageGroup: p.age_group,
        team: p.team,
        position: p.position,
        status: p.status || ""
      }))
    });
  } catch (err) {
    return c.json({ success: false, message: "Failed to fetch linked children", error: err.message }, 500);
  }
});
app.get("/api/notifications", async (c) => {
  const db = getDB(c);
  let userId = "";
  const authHeader = c.req.header("Authorization");
  if (authHeader && authHeader.startsWith("Bearer ")) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify2(token, getSecret(c), "HS256");
      if (payload && payload.sub) {
        userId = payload.sub;
      }
    } catch (e) {
      console.warn("[Observer Log] JWT verification optional for notifications list:", e);
    }
  }
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'general',
        is_read INTEGER DEFAULT 0,
        action_route TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `).run().catch(() => {
    });
    const query = userId ? `
      SELECT id, user_id, title, body, type, is_read, action_route, created_at
      FROM notifications
      WHERE user_id = ? OR user_id = 'ALL' OR user_id IS NULL OR user_id = ''
      ORDER BY created_at DESC
    ` : `
      SELECT id, user_id, title, body, type, is_read, action_route, created_at
      FROM notifications
      WHERE user_id = 'ALL' OR user_id IS NULL OR user_id = ''
      ORDER BY created_at DESC
    `;
    const { results } = userId ? await db.prepare(query).bind(userId).all() : await db.prepare(query).all();
    const notifications = results || [];
    const unreadCount = notifications.filter((n) => n.is_read === 0).length;
    console.log(`[Observer Log] Fetched ${notifications.length} notifications for user '${userId}' (Unread: ${unreadCount})`);
    return c.json({
      success: true,
      data: {
        notifications: notifications.map((n) => ({
          id: n.id,
          userId: n.user_id,
          title: n.title,
          body: n.body,
          type: n.type,
          isRead: Boolean(n.is_read),
          actionRoute: n.action_route || null,
          createdAt: n.created_at
        })),
        unreadCount
      }
    });
  } catch (err) {
    console.error("[Observer Error] Failed to fetch notifications:", err);
    return c.json({
      success: true,
      data: {
        notifications: [],
        unreadCount: 0
      }
    });
  }
});
app.post("/api/notifications/:id/read", async (c) => {
  const id = c.req.param("id");
  const db = getDB(c);
  try {
    await db.prepare("UPDATE notifications SET is_read = 1 WHERE id = ?").bind(id).run();
    console.log(`[Observer Log] Marked notification ${id} as read`);
    return c.json({ success: true, message: "Notification marked as read" });
  } catch (err) {
    console.error("[Observer Error] Mark read failed:", err);
    return c.json({ success: false, message: "Failed to update notification", error: err.message }, 500);
  }
});
app.post("/api/notifications/read-all", async (c) => {
  const db = getDB(c);
  let userId = "";
  const authHeader = c.req.header("Authorization");
  if (authHeader && authHeader.startsWith("Bearer ")) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify2(token, getSecret(c), "HS256");
      if (payload && payload.sub) {
        userId = payload.sub;
      }
    } catch (_) {
    }
  }
  try {
    if (userId) {
      await db.prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ? OR user_id = 'ALL'").bind(userId).run();
    } else {
      await db.prepare("UPDATE notifications SET is_read = 1").run();
    }
    console.log("[Observer Log] Marked all notifications as read");
    return c.json({ success: true, message: "All notifications marked as read" });
  } catch (err) {
    console.error("[Observer Error] Mark all read failed:", err);
    return c.json({ success: false, message: "Failed to update notifications", error: err.message }, 500);
  }
});
app.delete("/api/notifications/:id", async (c) => {
  const id = c.req.param("id");
  const db = getDB(c);
  try {
    await db.prepare("DELETE FROM notifications WHERE id = ? OR CAST(id AS TEXT) = ?").bind(id, id.toString()).run();
    console.log(`[Observer Log] Deleted notification ${id}`);
    return c.json({ success: true, message: "Notification deleted" });
  } catch (err) {
    console.error("[Observer Error] Delete notification failed:", err);
    return c.json({ success: false, message: "Failed to delete notification", error: err.message }, 500);
  }
});
app.post("/api/notifications/:id/delete", async (c) => {
  const id = c.req.param("id");
  const db = getDB(c);
  try {
    await db.prepare("DELETE FROM notifications WHERE id = ? OR CAST(id AS TEXT) = ?").bind(id, id.toString()).run();
    console.log(`[Observer Log] Deleted notification ${id}`);
    return c.json({ success: true, message: "Notification deleted" });
  } catch (err) {
    console.error("[Observer Error] Delete notification failed:", err);
    return c.json({ success: false, message: "Failed to delete notification", error: err.message }, 500);
  }
});
app.post("/api/notifications/send", async (c) => {
  const db = getDB(c);
  let senderId = "";
  const authHeader = c.req.header("Authorization");
  if (authHeader && authHeader.startsWith("Bearer ")) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify2(token, getSecret(c), "HS256");
      if (payload && payload.sub) {
        senderId = payload.sub;
      }
    } catch (_) {
    }
  }
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const { title, text, body: textBody, type, userId } = body;
  const content = textBody || text;
  if (!title || !content) {
    return c.json({ success: false, message: "Title and body text are required" }, 400);
  }
  const targetUser = userId || senderId || "ALL";
  const notifType = type || "general";
  try {
    const res = await db.prepare(`
      INSERT INTO notifications (user_id, title, body, type, is_read, created_at)
      VALUES (?, ?, ?, ?, 0, CURRENT_TIMESTAMP)
    `).bind(targetUser, title, content, notifType).run();
    console.log(`[Observer Log] Created new notification '${title}' for user '${targetUser}'`);
    return c.json({
      success: true,
      message: "Notification sent successfully",
      data: {
        id: res.meta?.last_row_id || Date.now(),
        userId: targetUser,
        title,
        body: text,
        type: notifType,
        isRead: false
      }
    });
  } catch (err) {
    console.error("[Observer Error] Send notification failed:", err);
    return c.json({ success: false, message: "Failed to send notification", error: err.message }, 500);
  }
});
app.post("/api/coach/send-sms-otp", async (c) => {
  const url = new URL(c.req.url);
  url.pathname = "/api/sms/send-verification";
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.post("/api/sms/send-verification", async (c) => {
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const { phone, name } = body;
  if (!phone) {
    return c.json({ success: false, message: "Phone number is required" }, 400);
  }
  const otpCode = generateSecureOTP();
  let digitsOnly = phone.replace(/[^\d]/g, "");
  if (digitsOnly.startsWith("0")) {
    digitsOnly = "27" + digitsOnly.slice(1);
  } else if (!digitsOnly.startsWith("27")) {
    digitsOnly = "27" + digitsOnly;
  }
  const kv = getKV(c);
  if (kv) {
    try {
      await kv.put(`sms_otp:${digitsOnly}`, otpCode, { expirationTtl: 600 });
    } catch (kvErr) {
      console.warn("[Observer Warning] Could not store OTP in KV:", kvErr);
    }
  }
  const apiKey = c.env.INTERNAL_API_KEY;
  if (!apiKey) {
    return c.json({ success: false, message: "Internal API Key binding missing" }, 500);
  }
  try {
    const smsRes = await fetch("https://sms-service.codeways.co", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Internal-API-Key": apiKey
      },
      body: JSON.stringify({
        to: digitsOnly,
        message: `[AcademyPro] Your verification code is ${otpCode}. Valid for 10 minutes.`,
        senderId: "Agua",
        tag: "AguaGo"
      })
    });
    const resText = await smsRes.text();
    console.log(`[Observer Log] Sent SMS code to ${digitsOnly}, status: ${smsRes.status}, response: ${resText}`);
    return c.json({
      success: true,
      message: `Verification SMS sent successfully to ${digitsOnly}`,
      data: {
        phone: digitsOnly
      }
    });
  } catch (err) {
    console.error("[Observer Error] Failed to send SMS:", err);
    return c.json({ success: false, message: "SMS service request failed", error: err.message }, 500);
  }
});
app.post("/api/coach/verify-sms-otp", async (c) => {
  const url = new URL(c.req.url);
  url.pathname = "/api/sms/verify-code";
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.post("/api/sms/verify-code", async (c) => {
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: "Invalid JSON payload" }, 400);
  }
  const { phone, code } = body;
  if (!phone || !code) {
    return c.json({ success: false, message: "Phone number and verification code are required" }, 400);
  }
  let digitsOnly = phone.replace(/[^\d]/g, "");
  if (digitsOnly.startsWith("0")) {
    digitsOnly = "27" + digitsOnly.slice(1);
  } else if (!digitsOnly.startsWith("27")) {
    digitsOnly = "27" + digitsOnly;
  }
  const cleanCode = code.toString().trim();
  const kv = getKV(c);
  let storedOtp = null;
  if (kv) {
    try {
      storedOtp = await kv.get(`sms_otp:${digitsOnly}`);
    } catch (_) {
    }
  }
  if (storedOtp && storedOtp.trim() === cleanCode) {
    if (kv) {
      try {
        await kv.delete(`sms_otp:${digitsOnly}`);
      } catch (_) {
      }
    }
    console.log(`[Observer Log] Verified phone number ${digitsOnly} successfully with code ${cleanCode}`);
    return c.json({
      success: true,
      message: "Phone number verified successfully!"
    });
  }
  return c.json({
    success: false,
    message: "Invalid or expired verification code. Please check your SMS and try again."
  }, 400);
});
var index_default = app;
export {
  index_default as default
};
//# sourceMappingURL=index.js.map
