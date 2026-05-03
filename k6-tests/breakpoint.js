import http from "k6/http";
import { check } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://quickpizza.default.svc.cluster.local";

export const options = {
  scenarios: {
    breakpoint: {
      executor: "ramping-arrival-rate",
      startRate: 1,
      timeUnit: "1s",
      preAllocatedVUs: 200,
      maxVUs: 500,
      stages: [
        { duration: "30s", target: 10 },
        { duration: "30s", target: 30 },
        { duration: "30s", target: 60 },
        { duration: "30s", target: 100 },
        { duration: "30s", target: 150 },
        { duration: "30s", target: 200 },
      ],
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.50"],
  },
};

const HEADERS = {
  "Content-Type": "application/json",
  Authorization: "token abcdef0123456789",
};

export default function () {
  const payload = JSON.stringify({
    maxCaloriesPerSlice: 900,
    mustBeVegetarian: false,
    excludedIngredients: [],
    excludedTools: [],
    maxNumberOfToppings: 5,
    minNumberOfToppings: 2,
  });

  const pizzaRes = http.post(`${BASE_URL}/api/pizza`, payload, {
    headers: Object.assign({}, HEADERS, { "X-User-ID": `break-user-${__VU}` }),
  });
  check(pizzaRes, {
    "status is 200": (r) => r.status === 200,
    "response time < 5s": (r) => r.timings.duration < 5000,
  });
}
