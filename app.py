import flet as ft 
import psycopg2 
from psycopg2.extras import DictCursor 
from datetime import datetime
import os

# Константы
C = {"M": "#FFFFFF", "S": "#F4E8D3", "A": "#67BA80"}
DB_CONFIG = {"dbname": "master_pol", "user": "postgres", "password": "admin", "host": "localhost", "port": "5432"}

class DB:
    def __init__(self):
        try:
            self.conn = psycopg2.connect(**DB_CONFIG)
            print("Подключено к БД")
        except Exception as e:
            print(f"Ошибка подключения к БД: {e}")
            self.conn = None
    
    def q(self, sql, p=None):
        try:
            if not self.conn or self.conn.closed: self.__init__()
            with self.conn.cursor(cursor_factory=DictCursor) as c:
                c.execute(sql, p)
                self.conn.commit()
                try: return c.fetchall()
                except: return None
        except Exception as e:
            print(f"SQL error: {e}")
            return None
    
    def partners(self): 
        return self.q("SELECT p.id, p.name, pt.name as type, p.rating, p.director, p.phone, p.email, p.address, p.inn, calculate_partner_discount(p.id) as discount FROM partners p JOIN partner_types pt ON p.partner_type_id = pt.id ORDER BY p.name") or []
    
    def partner(self, id):
        r = self.q("SELECT * FROM partners WHERE id = %s", (id,))
        return r[0] if r else None
    
    def types(self): 
        return self.q("SELECT id, name FROM partner_types ORDER BY name") or []
    
    def sales(self, id): 
        return self.q("SELECT p.name as product_name, s.quantity, s.sale_date FROM sales s JOIN products p ON s.product_id = p.id WHERE s.partner_id = %s ORDER BY s.sale_date DESC", (id,)) or []
    
    def save(self, id, data):
        if id:
            return self.q("UPDATE partners SET name=%s, partner_type_id=%s, rating=%s, director=%s, phone=%s, email=%s, address=%s, inn=%s WHERE id=%s", (*data, id))
        else:
            return self.q("INSERT INTO partners (name, partner_type_id, rating, director, phone, email, address, inn) VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING id", data)

def main(page: ft.Page):
    db = DB()
    click = {"t": 0, "id": None}
    
    # Настройка страницы
    page.title = "Мастер пол - Система работы с партнерами"
    page.window_width, page.window_height = 1000, 700
    page.window_resizable = True
    page.theme = ft.Theme(font_family="Segoe UI")
    page.bgcolor = C["M"]
    page.window_icon = "resources/Мастер пол.ico" if os.path.exists("resources/Мастер пол.ico") else None
    
    # Компоненты интерфейса
    header = ft.Container(
        content=ft.Row([
            ft.Image(src="resources/Мастер пол.png" if os.path.exists("resources/Мастер пол.png") else None, width=100, height=100, fit=ft.ImageFit.CONTAIN),
            ft.Text("Система работы с партнерами", size=30, weight=ft.FontWeight.BOLD, color=C["A"])
        ], alignment=ft.MainAxisAlignment.START, vertical_alignment=ft.CrossAxisAlignment.CENTER),
        padding=ft.padding.only(left=20, top=20, bottom=20)
    )
    
    content = ft.Container(expand=True)
    
    # Вспомогательные функции
    def dlg(title, msg, then=None):
        page.dialog = ft.AlertDialog(
            title=ft.Text(title), content=ft.Text(msg),
            actions=[ft.TextButton("ОК", on_click=lambda _: [page.close_dialog(), then and then()])]
        )
        page.dialog.open = True
        page.update()
    
    def view(v): content.content = v; page.update()
    def to_list(): view(list_view())
    def to_form(id=None): view(form_view(id))
    def to_sales(id, name): view(sales_view(id, name))
    
    def dbl_click(id):
        t = datetime.now().timestamp()
        if click["id"] == id and t - click["t"] < 0.5: to_form(id); click["t"] = 0
        else: click["t"], click["id"] = t, id
    
    # Представления
    def list_view():
        partners = db.partners()
        add_btn = ft.Container(content=ft.ElevatedButton("Добавить партнера", on_click=lambda _: to_form(), bgcolor=C["A"], color=C["M"]),
                              padding=ft.padding.only(left=20, right=20), alignment=ft.alignment.center_right)
        
        if not partners:
            return ft.Column([add_btn, ft.Container(content=ft.Text("Нет данных о партнерах", size=18), 
                                                   alignment=ft.alignment.center, padding=20)], expand=True)
            
        cards = [ft.Card(content=ft.Container(content=ft.Column([
            ft.ListTile(title=ft.Text(f"{p['type']} | {p['name']}", size=18, weight=ft.FontWeight.BOLD),
                      subtitle=ft.Column([ft.Text(f"Директор: {p['director']}"), ft.Text(f"+{p['phone']}"), 
                                          ft.Text(f"Рейтинг: {p['rating']}")], spacing=5),
                      trailing=ft.Text(f"{p['discount']}%", size=24, weight=ft.FontWeight.BOLD, color=C["A"]),
                      on_click=lambda e, id=p["id"]: dbl_click(id)),
            ft.Row([ft.TextButton("Редактировать", on_click=lambda e, id=p["id"]: to_form(id)),
                    ft.TextButton("История продаж", on_click=lambda e, id=p["id"], n=p["name"]: to_sales(id, n))], 
                  alignment=ft.MainAxisAlignment.END)]), padding=10)) for p in partners]
        
        return ft.Column([add_btn, ft.ListView(controls=cards, expand=True, spacing=10, padding=20)], expand=True)
    
    def form_view(id=None):
        p = db.partner(id) if id else None
        
        f = {
            "name": ft.TextField(label="Наименование", value=p["name"] if p else ""),
            "type": ft.Dropdown(label="Тип партнера", options=[ft.dropdown.Option(text=t["name"], key=str(t["id"])) for t in db.types()],
                              value=str(p["partner_type_id"]) if p else None),
            "rating": ft.TextField(label="Рейтинг", input_filter=ft.NumbersOnlyInputFilter(), value=str(p["rating"]) if p else ""),
            "director": ft.TextField(label="ФИО директора", value=p["director"] if p else ""),
            "phone": ft.TextField(label="Телефон", value=p["phone"] if p else ""),
            "email": ft.TextField(label="Email", value=p["email"] if p else ""),
            "address": ft.TextField(label="Адрес", value=p["address"] if p else ""),
            "inn": ft.TextField(label="ИНН", value=p["inn"] if p else "")
        }
        
        def save(_):
            for k, label in [("name", "Наименование"), ("type", "Тип"), ("director", "ФИО директора"), 
                           ("phone", "Телефон"), ("email", "Email"), ("address", "Адрес"), ("inn", "ИНН")]:
                if not f[k].value: return dlg("Ошибка", f"Поле '{label}' обязательно для заполнения")
            
            try:
                rating = int(f["rating"].value)
                if rating < 0: return dlg("Ошибка", "Рейтинг должен быть неотрицательным числом")
            except: return dlg("Ошибка", "Рейтинг должен быть целым числом")
            
            try:
                data = [f["name"].value, int(f["type"].value), int(f["rating"].value), f["director"].value, 
                        f["phone"].value, f["email"].value, f["address"].value, f["inn"].value]
                db.save(id, data)
                to_list()
            except Exception as ex: dlg("Ошибка", f"Ошибка при сохранении: {str(ex)}")
        
        return ft.Column([
            ft.Container(content=ft.Row([ft.IconButton(icon=ft.Icons.ARROW_BACK, on_click=lambda _: to_list()),
                                        ft.Text(f"{'Редактирование' if id else 'Добавление'} партнера", 
                                               size=24, weight=ft.FontWeight.BOLD, color=C["A"])]),
                         padding=ft.padding.only(left=20, top=20, bottom=20)),
            ft.Container(content=ft.Column([*f.values(), 
                                          ft.Row([ft.ElevatedButton("Отмена", on_click=lambda _: to_list()),
                                                 ft.ElevatedButton("Сохранить", on_click=save, bgcolor=C["A"], color=C["M"])], 
                                                alignment=ft.MainAxisAlignment.END)], spacing=20),
                        padding=20, bgcolor=C["S"], border_radius=10)
        ], expand=True, spacing=20, scroll=ft.ScrollMode.AUTO)
    
    def sales_view(id, name):
        sales = db.sales(id)
        
        content_widget = (ft.Text("История реализации продукции отсутствует", size=16) if not sales else 
                          ft.DataTable(columns=[ft.DataColumn(ft.Text("Наименование продукции")),
                                               ft.DataColumn(ft.Text("Количество")),
                                               ft.DataColumn(ft.Text("Дата продажи"))],
                                      rows=[ft.DataRow(cells=[ft.DataCell(ft.Text(s["product_name"])),
                                                             ft.DataCell(ft.Text(str(s["quantity"]))),
                                                             ft.DataCell(ft.Text(s["sale_date"].strftime("%d.%m.%Y")))]) 
                                            for s in sales],
                                      border=ft.border.all(1, "#DDDDDD"), border_radius=10,
                                      horizontal_lines=ft.border.BorderSide(1, "#EEEEEE"),
                                      vertical_lines=ft.border.BorderSide(1, "#EEEEEE"), column_spacing=50))
        
        return ft.Column([
            ft.Container(content=ft.Row([ft.IconButton(icon=ft.Icons.ARROW_BACK, on_click=lambda _: to_list()),
                                        ft.Text(f"История реализации продукции: {name}", size=24, weight=ft.FontWeight.BOLD, color=C["A"])]),
                         padding=ft.padding.only(left=20, top=20, bottom=20)),
            ft.Container(content=content_widget, padding=20, bgcolor=C["S"], border_radius=10, margin=20)
        ], expand=True, scroll=ft.ScrollMode.AUTO)
    
    to_list()
    page.add(header, content)

if __name__ == "__main__":
    ft.app(target=main)