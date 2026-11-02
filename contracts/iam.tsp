import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";
import "../docs/event-model/models/iam/contracts/iam.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;

@service(#{ title: "Nemeo API" })
@server("http://localhost:3000", "Local development")
namespace Nemeo;

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

model HouseholdCollectionResponse {
  data: IAM.CurrentHousehold[];
  hasMore: boolean;
  nextCursor?: string;
}

@route("/v1/auth/google/start")
@get
op startGoogleAuthentication(): RedirectResponse;

@route("/v1/auth/google/callback")
@get
op completeGoogleAuthentication(...GoogleAuthCallbackQuery): RedirectResponse;

@route("/v1/households")
@get
op listHouseholds(): HouseholdCollectionResponse;

@route("/v1/households")
@post
op createInitialHousehold(@body body: CreateInitialHouseholdRequest): IAM.CurrentHousehold;
