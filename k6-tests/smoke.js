import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://quickpizza.default.svc.cluster.local";

export const options = {
  vus: 1,
  duration: "30s",
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed: ["rate<0.01"],
  },
};

const PIZZA_PAYLOAD = JSON.stringify({
  maxCaloriesPerSlice: 1000,
  mustBeVegetarian: false,
  excludedIngredients: [],
  excludedTools: [],
  maxNumberOfToppings: 6,
  minNumberOfToppings: 2,
});

const HEADERS = {
  "Content-Type": "application/json",
  // Required by QuickPizza API (see grafana/quickpizza k6/foundations/01.basic.js)
  Authorization: "token abcdef0123456789",
  "X-User-ID": "smoke-test-user",
};

export default function () {
  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, {
    "homepage status is 200": (r) => r.status === 200,
  });

  const pizzaRes = http.post(`${BASE_URL}/api/pizza`, PIZZA_PAYLOAD, {
    headers: HEADERS,
  });
  check(pizzaRes, {
    "pizza API status is 200": (r) => r.status === 200,
    "pizza response has name": (r) => JSON.parse(r.body).pizza?.name !== undefined,
  });

  sleep(1);
}
