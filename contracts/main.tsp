import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";

using TypeSpec.Http;
using TypeSpec.Rest;

@service(#{ title: "Nemeo API" })
@server("http://localhost:3000", "Local development")
namespace Nemeo;

model HealthResponse {
  status: "ok";
}

@route("/health")
@get
op health(): HealthResponse;
