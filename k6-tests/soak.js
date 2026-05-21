import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://quickpizza.default.svc.cluster.local";

export const options = {
  stages: [
    { duration: "30s", target: 10 },
    { duration: "5m",  target: 10 },
    { duration: "30s", target: 0 },
  ],
  thresholds: {
    http_req_duration: ["p(95)<1000"],
    http_req_failed: ["rate<0.05"],
  },
};

const HEADERS = {
  "Content-Type": "application/json",
  Authorization: "token abcdef0123456789",
};

export default function () {
  const payload = JSON.stringify({
    maxCaloriesPerSlice: 1000,
    mustBeVegetarian: Math.random() > 0.7,
    excludedIngredients: [],
    excludedTools: [],
    maxNumberOfToppings: Math.floor(Math.random() * 4) + 3,
    minNumberOfToppings: 2,
  });

  const pizzaRes = http.post(`${BASE_URL}/api/pizza`, payload, {
    headers: Object.assign({}, HEADERS, { "X-User-ID": `soak-user-${__VU}` }),
  });
  check(pizzaRes, {
    "status is 200": (r) => r.status === 200,
  });

  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, { "homepage OK": (r) => r.status === 200 });

  sleep(1);
}
