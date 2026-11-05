extends RefCounted
class_name EconomyRules

static func buy(balance: int, price: int, quantity: int = 1) -> Dictionary:
	var total: int = maxi(0, price) * maxi(0, quantity)
	if quantity <= 0 or balance < total:
		return {"ok": false, "balance": balance, "quantity": 0}
	return {"ok": true, "balance": balance - total, "quantity": quantity}

static func sell(balance: int, unit_price: int, requested: int, owned: int) -> Dictionary:
	var quantity: int = clampi(requested, 0, maxi(0, owned))
	return {"ok": quantity > 0, "balance": balance + maxi(0, unit_price) * quantity, "quantity": quantity}

static func upgrade(level: int, balance: int, wood: int, stone: int) -> Dictionary:
	var can_upgrade: bool = level < 6 and balance >= 80 and wood >= 3 and stone >= 2
	return {"ok": can_upgrade, "level": level + 1 if can_upgrade else level, "balance": balance - 80 if can_upgrade else balance, "wood": wood - 3 if can_upgrade else wood, "stone": stone - 2 if can_upgrade else stone}
