import "@typespec/http";
import "@typespec/rest";

using TypeSpec.Http;
using TypeSpec.Rest;

namespace Nemeo;

model HealthResponse {
  status: "ok";
}

@route("/health")
@get
op health(): HealthResponse;
