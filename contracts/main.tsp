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

model RedirectResponse {
  @statusCode
  statusCode: 302;

  @header("Location")
  location: string;
}

model GoogleAuthCallbackQuery {
  @query
  code: string;

  @query
  state: string;

  @query
  error?: string;
}

model CreateInitialHouseholdRequest {
  name: string;
}

model HouseholdResponse {
  id: string;
  name: string;
  role: "manager";
}

@route("/health")
@get
op health(): HealthResponse;

@route("/v1/auth/google/start")
@get
op startGoogleAuthentication(): RedirectResponse;

@route("/v1/auth/google/callback")
@get
op completeGoogleAuthentication(...GoogleAuthCallbackQuery): RedirectResponse;

@route("/v1/household")
@get
op getCurrentHousehold(): HouseholdResponse;

@route("/v1/households")
@post
op createInitialHousehold(@body body: CreateInitialHouseholdRequest): HouseholdResponse;
