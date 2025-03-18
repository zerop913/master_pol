import unittest
from unittest.mock import MagicMock, patch
import sys
import os
from datetime import datetime

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app import DB, DB_CONFIG

class TestDB(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """Выполняется один раз перед всеми тестами"""
        print("\n=== Начало тестирования ===")
        cls.patcher = patch('psycopg2.connect')
        cls.mock_connect = cls.patcher.start()
    
    @classmethod
    def tearDownClass(cls):
        cls.patcher.stop()
    
    def setUp(self):
        self.mock_connection = MagicMock()
        self.mock_cursor = MagicMock()
        self.mock_connection.cursor.return_value.__enter__.return_value = self.mock_cursor
        self.__class__.mock_connect.return_value = self.mock_connection
        self.db = DB()

    def test_db_connection(self):
        """Тест подключения к БД"""
        print("\nТест подключения к БД")
        with patch('psycopg2.connect') as mock_connect:
            mock_connect.return_value = MagicMock()
            db = DB()
            mock_connect.assert_called_once_with(**DB_CONFIG)
            print("✓ Подключение успешно")
            self.assertIsNotNone(db)

    def test_query_execution(self):
        """Тест выполнения запроса"""
        self.mock_cursor.fetchall.return_value = [{"id": 1, "name": "Test"}]
        
        result = self.db.q("SELECT * FROM test")
        self.assertEqual(result, [{"id": 1, "name": "Test"}])

    def test_partners_list(self):
        """Тест получения списка партнеров"""
        mock_data = [
            {"id": 1, "name": "Test Partner", "type": "ООО", "rating": 5,
             "director": "John Doe", "phone": "123456", "email": "test@test.com",
             "address": "Test Address", "inn": "123456789", "discount": 5}
        ]
        self.db.q = MagicMock(return_value=mock_data)
        result = self.db.partners()
        self.assertEqual(result, mock_data)

    def test_partners_list_empty(self):
        """Тест получения пустого списка партнеров"""
        self.db.q = MagicMock(return_value=None)
        result = self.db.partners()
        self.assertEqual(result, [])

    def test_partner_by_id(self):
        """Тест получения партнера по ID"""
        mock_data = [{"id": 1, "name": "Test Partner"}]
        self.db.q = MagicMock(return_value=mock_data)
        result = self.db.partner(1)
        self.assertEqual(result, mock_data[0])

    def test_partner_not_found(self):
        """Тест поиска несуществующего партнера"""
        self.db.q = MagicMock(return_value=None)
        result = self.db.partner(999)
        self.assertIsNone(result)

    def test_types_list(self):
        """Тест получения списка типов"""
        mock_data = [
            {"id": 1, "name": "ООО"},
            {"id": 2, "name": "ЗАО"}
        ]
        self.db.q = MagicMock(return_value=mock_data)
        result = self.db.types()
        self.assertEqual(result, mock_data)

    def test_sales_list(self):
        """Тест получения списка продаж"""
        mock_data = [
            {"product_name": "Test Product", "quantity": 100, "sale_date": "2024-01-01"}
        ]
        self.db.q = MagicMock(return_value=mock_data)
        result = self.db.sales(1)
        self.assertEqual(result, mock_data)

    def test_save_partner_new(self):
        """Тест сохранения нового партнера"""
        test_data = ["Test Name", 1, 5, "Director", "123456", "test@test.com", "Address", "123456789"]
        self.mock_cursor.fetchall.return_value = [{"id": 1}]
        result = self.db.save(None, test_data)
        self.assertIsNotNone(result)

    def test_save_partner_update(self):
        """Тест обновления существующего партнера"""
        test_data = ["Test Name", 1, 5, "Director", "123456", "test@test.com", "Address", "123456789"]
        self.mock_cursor.fetchall.return_value = None
        result = self.db.save(1, test_data)
        self.assertIsNone(result)

if __name__ == '__main__':
    print("\n=== Запуск тестов для системы работы с партнерами ===")
    unittest.main(verbosity=2, argv=[''], exit=False)
