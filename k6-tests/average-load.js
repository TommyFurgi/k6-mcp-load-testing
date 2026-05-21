import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://quickpizza.default.svc.cluster.local";

export const options = {
  stages: [
    { duration: "30s", target: 10 },
    { duration: "1m",  target: 10 },
    { duration: "30s", target: 0 },
  ],
  thresholds: {
    http_req_duration: ["p(95)<800", "p(99)<1500"],
    http_req_failed: ["rate<0.05"],
  },
};

const HEADERS = {
  "Content-Type": "application/json",
  Authorization: "token abcdef0123456789",
  "X-User-ID": "avg-load-user",
};

export default function () {
  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, { "homepage 200": (r) => r.status === 200 });

  const payload = JSON.stringify({
    maxCaloriesPerSlice: 1000,
    mustBeVegetarian: Math.random() > 0.5,
    excludedIngredients: [],
    excludedTools: [],
    maxNumberOfToppings: Math.floor(Math.random() * 5) + 2,
    minNumberOfToppings: 2,
  });

  const pizzaRes = http.post(`${BASE_URL}/api/pizza`, payload, {
    headers: HEADERS,
  });
  check(pizzaRes, {
    "pizza API 200": (r) => r.status === 200,
  });

  sleep(Math.random() * 2 + 0.5);
}
