# run with "rails runner -e production PATH_TO_THIS_FILE"
# WARNING: USE AT YOUR OWN RISK!!!

model = Model.find_by(name: "Bürostuhl sedus se:motion schwarz em-101")
pool = InventoryPool.find_by(name: "FM Inventar")

reservations = Reservation
  .where(model_id: model.id)
  .where(inventory_pool_id: pool.id)
  .where(status: :signed)
  .where('end_date < ? ', Date.today)

reservations.update_all(end_date: Date.today + 10.years)
