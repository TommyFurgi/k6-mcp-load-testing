import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://quickpizza.default.svc.cluster.local";

export const options = {
  stages: [
    { duration: "10s", target: 1 },
    { duration: "5s",  target: 100 },
    { duration: "30s", target: 100 },
    { duration: "5s",  target: 1 },
    { duration: "20s", target: 1 },
  ],
  thresholds: {
    http_req_duration: ["p(95)<3000"],
    http_req_failed: ["rate<0.15"],
  },
};

const HEADERS = {
  "Content-Type": "application/json",
  Authorization: "token abcdef0123456789",
};

export default function () {
  const payload = JSON.stringify({
    maxCaloriesPerSlice: 1200,
    mustBeVegetarian: false,
    excludedIngredients: [],
    excludedTools: [],
    maxNumberOfToppings: 8,
    minNumberOfToppings: 1,
  });

  const pizzaRes = http.post(`${BASE_URL}/api/pizza`, payload, {
    headers: Object.assign({}, HEADERS, { "X-User-ID": `spike-user-${__VU}` }),
  });
  check(pizzaRes, {
    "status is 200": (r) => r.status === 200,
  });

  sleep(0.5);
}
