import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://quickpizza.default.svc.cluster.local";

export const options = {
  stages: [
    { duration: "20s", target: 10 },
    { duration: "20s", target: 30 },
    { duration: "30s", target: 50 },
    { duration: "30s", target: 50 },
    { duration: "20s", target: 0 },
  ],
  thresholds: {
    http_req_duration: ["p(95)<2000"],
    http_req_failed: ["rate<0.10"],
  },
};

const HEADERS = {
  "Content-Type": "application/json",
  Authorization: "token abcdef0123456789",
};

export default function () {
  const userId = `stress-user-${__VU}`;

  const payload = JSON.stringify({
    maxCaloriesPerSlice: 800,
    mustBeVegetarian: false,
    excludedIngredients: [],
    excludedTools: [],
    maxNumberOfToppings: 6,
    minNumberOfToppings: 1,
  });

  const pizzaRes = http.post(`${BASE_URL}/api/pizza`, payload, {
    headers: Object.assign({}, HEADERS, { "X-User-ID": userId }),
  });
  check(pizzaRes, {
    "status is 200": (r) => r.status === 200,
    "response time < 2s": (r) => r.timings.duration < 2000,
  });

  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, { "homepage OK": (r) => r.status === 200 });

  sleep(0.3);
}
