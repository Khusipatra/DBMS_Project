# Budget-Constrained Purchase Planning with the Fractional Knapsack

Part of the project *Supply Chain Demand Forecasting and Inventory Optimization*.

## 1. Problem

A business rarely has enough money to buy every product it needs. After the forecasting step, the system knows how many units of each product-warehouse pair will be needed, but the total cost of buying all of them may exceed the budget.

**Question:** given a fixed budget, which products should be bought, and how much of each, so that the total expected profit is as high as possible?

## 2. Why the Fractional Knapsack

The classic knapsack problem has a bag with a weight limit and items with a weight and a value. Mapped to this project:

| Knapsack term | Project meaning |
|---|---|
| Bag capacity | Total purchase budget (in rupees) |
| Item weight | Cost of buying the required units of a product |
| Item value | Profit earned from selling those units |
| Item | One SKU-warehouse pair |

In the **fractional** version an item can be taken partly. This fits purchasing well, because a business can buy part of the required quantity of a product. For this version a greedy method is provably optimal, and it is fast and easy to explain.

## 3. Key metric: profit-to-cost ratio

```
profit per unit       = unit_price - unit_cost
profit-to-cost ratio  = profit per unit / unit_cost
```

The ratio is the profit earned per rupee invested. A product with a ratio of 0.60 returns 60 paise of profit for each rupee spent.

## 4. Algorithm

1. For each product, compute `required_units`, `total_cost = required_units x unit_cost` and `total_profit = required_units x (unit_price - unit_cost)`.
2. Compute the profit-to-cost ratio for each product.
3. Sort products by ratio, highest first.
4. Go down the list with the remaining budget:
   - If the whole product fits, buy all of it and subtract its cost.
   - If it does not fit, buy the fraction `remaining_budget / total_cost` and stop.
5. Save the result in `PURCHASE_PLAN`.

**Complexity:** O(n log n), dominated by the sort.

**Why greedy is optimal:** suppose a better plan spent money on a lower-ratio product while part of a higher-ratio product was left unbought. Moving one rupee from the lower-ratio product to the higher-ratio one raises total profit, so that plan was not optimal. Repeating this argument shows that spending in order of ratio cannot be beaten.

## 5. Worked example

Budget: Rs 10,000. These numbers are for illustration only.

| Product | Required units | Unit cost | Unit price | Total cost | Total profit | Ratio |
|---|---|---|---|---|---|---|
| A | 100 | 50 | 70 | 5,000 | 2,000 | 0.40 |
| B | 80 | 100 | 160 | 8,000 | 4,800 | 0.60 |
| C | 200 | 20 | 25 | 4,000 | 1,000 | 0.25 |
| D | 50 | 200 | 260 | 10,000 | 3,000 | 0.30 |

Sorted by ratio: B (0.60), A (0.40), D (0.30), C (0.25).

| Step | Product | Budget left before | Action | Spent | Profit |
|---|---|---|---|---|---|
| 1 | B | 10,000 | Buy all 80 units | 8,000 | 4,800 |
| 2 | A | 2,000 | Buy 2,000 / 5,000 = 0.4 of A, which is 40 units | 2,000 | 800 |
| 3 | D | 0 | Nothing left | 0 | 0 |
| 4 | C | 0 | Nothing left | 0 | 0 |

**Result:** total spent Rs 10,000, expected profit Rs 5,600.

Product D has a large total profit (3,000), but it costs the whole budget for a low ratio. Ranking by total profit would pick D and earn only Rs 3,000. Ranking by ratio earns Rs 5,600.

## 6. How it fits into the project

```
DAILY_RECORD -> forecasting -> FORECAST -> required units
                                          |
SKU_WAREHOUSE (unit cost, unit price) ----+-> cost, profit, ratio
                                          |
                  budget (user input) ----+-> Fractional Knapsack -> PURCHASE_PLAN -> app
```

**Inputs**

- `FORECAST.forecast_units`: expected demand for the planning period.
- Current inventory from `DAILY_RECORD` (the latest `inventory_level`).
- `SKU_WAREHOUSE.unit_cost` and `unit_price`.
- A budget entered by the user in the app.

**Required units**

```
required_units = max(0, forecast_units - current_inventory)
```

Safety stock from `INVENTORY_ANALYTICS` can be added to this figure so that the plan also covers the buffer.

**Use of the confidence interval**

- `forecast_units` gives the expected profit.
- `lower_bound` gives a conservative profit estimate: if demand is at the low end, less is sold, so profit is smaller.
- `upper_bound` shows how many units might be needed in the high-demand case, which supports the safety stock figure.

The app can show the plan under the expected case and the conservative case side by side.

**Output table: `PURCHASE_PLAN`**

| Column | Meaning |
|---|---|
| `sku_wh_id` | the product-warehouse pair |
| `budget` | budget used for this run |
| `total_cost` | cost of buying all required units |
| `total_profit` | profit if all required units are sold |
| `profit_cost_ratio` | profit per rupee invested |
| `fraction_selected` | share of the required units to buy (0 to 1) |

Units to buy = `fraction_selected x required_units`. Money allocated = `fraction_selected x total_cost`.

## 7. Conclusion

The Fractional Knapsack gives a clear rule for spending a limited budget: rank products by profit per rupee and fund them in that order until the money runs out. It connects the forecast and the algorithm to a real business decision, turning predicted demand into a purchase plan that maximizes expected profit within the budget.
