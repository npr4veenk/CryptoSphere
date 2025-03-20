from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
import sqlite3
from pydantic import BaseModel
from typing import List, Dict
import time
import math

app = FastAPI()

class User(BaseModel): #add_usr
    email: str
    username: str
    password: str
    profilePicture: str

class CoinDetails(BaseModel):
    id: int
    coinSymbol: str
    coinName: str
    imageUrl: str

class UserHoldings(BaseModel):
    email: str
    coin: CoinDetails
    quantity: float

def init_db():
    with sqlite3.connect("chat.db") as conn:
        # conn.execute('drop table users')
        conn.execute('''CREATE TABLE IF NOT EXISTS users 
                       (id INTEGER PRIMARY KEY, email TEXT UNIQUE, username TEXT UNIQUE, password TEXT, profilePicture TEXT)''')
        
        conn.execute("CREATE TABLE IF NOT EXISTS coins (id INTEGER PRIMARY KEY, coinName TEXT UNIQUE, coinSymbol TEXT, imageUrl TEXT)")
        
        conn.execute('''CREATE TABLE IF NOT EXISTS user_coins
                (id INTEGER PRIMARY KEY,
                user_id INTEGER,
                coin_id INTEGER,
                quantity REAL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(user_id) REFERENCES users(id),
                FOREIGN KEY(coin_id) REFERENCES coins(id))''')

        conn.execute('''CREATE TABLE IF NOT EXISTS chats 
                       (id INTEGER PRIMARY KEY, from_user TEXT, to_user TEXT, message TEXT, timestamp INTEGER)''')

init_db()
    
@app.get("/userholdings/{username}", response_model=List[UserHoldings])
async def get_wallet_details(username: str):
    with sqlite3.connect("chat.db") as conn:
        cursor = conn.cursor()
        
        # Get user email
        cursor.execute("SELECT email FROM users WHERE username = ?", (username,))
        user_email = cursor.fetchone()
        if not user_email:
            raise HTTPException(status_code=404, detail="User mail not found")
        
        # Get wallet details
        # First get user_id from username
        cursor.execute("SELECT id FROM users WHERE username = ?", (username,))
        user_id = cursor.fetchone()
        if not user_id:
            raise HTTPException(status_code=404, detail="User id not found")
        
        cursor.execute('''SELECT 
                            c.id AS coin_id,
                            c.coinSymbol,
                            c.coinName,
                            c.imageUrl,
                            SUM(uc.quantity) AS total_quantity
                        FROM user_coins uc
                        JOIN coins c ON uc.coin_id = c.id
                        WHERE uc.user_id = ?
                        GROUP BY c.id, c.coinSymbol, c.coinName, c.imageUrl''', (user_id[0],))
        rows = cursor.fetchall()
        
        return [UserHoldings(
            email=user_email[0],
            coin=CoinDetails(
                id=row[0],
                coinSymbol=row[1].upper() + "USDT",
                coinName=row[2],
                imageUrl=row[3]
            ),
            quantity=row[4],
        ) for row in rows]

@app.get("/")
async def index():
    return {"message": "P2P Chat App"}

@app.post("/add_user")
async def add_user(user: User):
    try:
        with sqlite3.connect("chat.db") as conn:
            cursor = conn.cursor()
            # Insert new user
            cursor.execute("INSERT INTO users (email, username, password, profilePicture) VALUES (?, ?, ?, ?)", 
                         (user.email, user.username, user.password, user.profilePicture))
            conn.commit()
            print("👤 User added:", user.email, user.username)
            return {"id": user.email}
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Email or username exists")

@app.get("/get_users", response_model=List[User])
async def get_all_users():
    with sqlite3.connect("chat.db") as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT email, username, password, profilePicture FROM users")
        return [{"email": row[0], "username": row[1], "password": row[2], "profilePicture": row[3]} 
                for row in cursor.fetchall()]
    
@app.get("/buy_coin")
async def buy_coin(username: str, coin_id: int, quantity: float):
    print(quantity)
    try:
        with sqlite3.connect("chat.db") as conn:
            cursor = conn.cursor()
            
            # First check if user exists
            cursor.execute("SELECT id FROM users WHERE username = ?", (username,))
            user = cursor.fetchone()
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            
            # Check if coin exists
            cursor.execute("SELECT coinName FROM coins WHERE id = ?", (coin_id,))
            coin = cursor.fetchone()
            if not coin:
                raise HTTPException(status_code=404, detail="Coin not found")
            
            # Validate quantity
            if quantity <= 0:
                raise HTTPException(status_code=400, detail="Quantity must be positive")
            
            # Get current balance of the user for this coin
            cursor.execute('''
                SELECT quantity 
                FROM user_coins 
                WHERE user_id = (SELECT id FROM users WHERE username = ?) AND coin_id = ?
            ''', (username, coin_id))
            balance = cursor.fetchone()
            if not balance:
                cursor.execute('''
                    INSERT INTO user_coins (user_id, coin_id, quantity)
                    VALUES ((SELECT id FROM users WHERE username = ?), ?, ?)
                ''', (username, coin_id, quantity))
            else:
                cursor.execute('''
                    UPDATE user_coins 
                    SET quantity = quantity + ?
                    WHERE user_id = (SELECT id FROM users WHERE username = ?) AND coin_id = ?
                ''', (quantity, username, coin_id))
            
            conn.commit()
            print(f"🪙 {username} bought {quantity} of coin {coin[0]}")
            return {"status": "success", "message": f"Successfully bought {quantity} of coin {coin_id}"}
            
    except sqlite3.Error as e:
        print(f"Database error: {e}")
        raise HTTPException(status_code=500, detail="Database error")
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/sell_coin")
async def sell_coin(username: str, coin_id: int, quantity: float):
    try:
        with sqlite3.connect("chat.db") as conn:
            cursor = conn.cursor()
            
            # First check if user exists
            cursor.execute("SELECT id FROM users WHERE username = ?", (username,))
            user = cursor.fetchone()
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            
            # Check if coin exists
            cursor.execute("SELECT id FROM coins WHERE id = ?", (coin_id,))
            coin = cursor.fetchone()
            if not coin:
                raise HTTPException(status_code=404, detail="Coin not found")
            
            # Validate quantity
            if quantity <= 0:
                raise HTTPException(status_code=400, detail="Quantity must be positive")
            
            # Get current balance of the user for this coin
            cursor.execute('''
                SELECT quantity 
                FROM user_coins 
                WHERE user_id = (SELECT id FROM users WHERE username = ?) AND coin_id = ?
            ''', (username, coin_id))
            balance = cursor.fetchone()
            
            if not balance or not balance[0] or float(balance[0]) < quantity:
                raise HTTPException(status_code=400, detail="Insufficient balance")
            
            # Update user's balance by deducting the sold amount
            cursor.execute('''
                UPDATE user_coins 
                SET quantity = quantity - ?
                WHERE user_id = (SELECT id FROM users WHERE username = ?) AND coin_id = ?
            ''', (quantity, username, coin_id))
            
            conn.commit()
            print(f"🪙 {username} sold {quantity} of coin {coin_id}")
            return {"status": "success", "message": f"Successfully sold {quantity} of coin {coin_id}"}
            
    except sqlite3.Error as e:
        print(f"Database error: {e}")
        raise HTTPException(status_code=500, detail="Database error")
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/get_coins/{page}/{search}")
async def get_coins_page(page: int, search: str = None):
    with sqlite3.connect("chat.db") as conn:
        cursor = conn.cursor()
        limit = 25
        offset = (page - 1) * limit
        
        if search != "@All":
            search_term = f"%{search.lower()}%"
            # Get total count
            cursor.execute("""
                SELECT COUNT(*) 
                FROM coins 
                WHERE LOWER(coinSymbol) LIKE ? OR LOWER(coinName) LIKE ?
            """, (search_term, search_term))
            total_count = cursor.fetchone()[0]
            
            # Get paginated results
            cursor.execute("""
                SELECT id, coinSymbol, coinName, imageUrl 
                FROM coins 
                WHERE LOWER(coinSymbol) LIKE ? OR LOWER(coinName) LIKE ?
                ORDER BY 
                    CASE 
                        WHEN LOWER(coinName) LIKE ? THEN 1
                        WHEN LOWER(coinName) LIKE ? THEN 2
                        ELSE 3
                    END,
                    coinName
                LIMIT ? OFFSET ?
            """, (search_term, search_term, f"{search_term[1:]}%", f"%{search_term[1:]}%", limit, offset))
        else:
            # Get total count
            cursor.execute("SELECT COUNT(*) FROM coins")
            total_count = cursor.fetchone()[0]
            
            # Get paginated results
            cursor.execute("""
                SELECT id, coinSymbol, coinName, imageUrl 
                FROM coins 
                ORDER BY id
                LIMIT ? OFFSET ?
            """, (limit, offset))
            
        coin = [{"id": int(row[0]), "coinSymbol": row[1].upper() + "USDT", "coinName": row[2], "imageUrl": row[3]} 
                for row in cursor.fetchall()]
        
        total_pages = math.ceil(total_count / limit)  # Calculate total pages using ceiling function
        print(f"₿ Fetched page {page} of {total_pages} total pages for search : '{search}' of coins")
        return {
            "coin": coin,
            "total_pages": total_pages
        }

        
@app.get("/coins/{coin_symbol}", response_model=CoinDetails)
async def get_coin(coin_symbol: str):
    with sqlite3.connect("chat.db") as conn:
        coin_symbol = coin_symbol.lower().replace("usdt", "")
        cursor = conn.cursor()
        cursor.execute("SELECT id, coinSymbol, coinName, imageUrl FROM coins WHERE LOWER(coinSymbol) = LOWER(?)", (coin_symbol,))
        row = cursor.fetchone()

        if row:
            return {"id": row[0], "coinSymbol": row[1].upper() + "USDT", "coinName": row[2], "imageUrl": row[3]}
        else:
            raise HTTPException(status_code=404, detail="Coin not found")
        

@app.get("/name_coin/{coinSymbol}", response_model=CoinDetails)
async def get_coin_by_name(coinSymbol: str):
    with sqlite3.connect("chat.db") as conn:
        cursor = conn.cursor()
        coinSymbol = coinSymbol.lower().replace("usdt", "")
        cursor.execute("SELECT id, coinSymbol, coinName, imageUrl FROM coins WHERE LOWER(coinName) = LOWER(?)", (coinSymbol,))
        row = cursor.fetchone()
        
        if row:
            return {"id": row[0], "coinSymbol": row[1].upper() + "USDT", "coinName": row[2], "imageUrl": row[3]}
        else:
            raise HTTPException(status_code=404, detail="Coin not found")

@app.get("/get_chat_history/{from_user}")
async def get_chat_history(from_user: str):
    with sqlite3.connect("chat.db") as conn:
        cursor = conn.cursor()
        # Get all unique users that from_user has chatted with
        cursor.execute('''
            SELECT DISTINCT CASE 
                WHEN from_user = ? THEN to_user 
                ELSE from_user 
            END as other_user
            FROM chats 
            WHERE from_user = ? OR to_user = ?
        ''', (from_user, from_user, from_user))
        
        users = [row[0] for row in cursor.fetchall()]
        
        # Get chat history for each user
        chat_history = []
        for user in users:
            cursor.execute('''
                SELECT from_user, to_user, message, timestamp
                FROM chats 
                WHERE (from_user = ? AND to_user = ?) OR (to_user = ? AND from_user = ?)
                ORDER BY timestamp
            ''', (from_user, user, from_user, user))
            
            rows = cursor.fetchall()
            chat_history.extend([{"from": row[0], "to": row[1], "message": row[2], "timestamp": row[3]} 
                               for row in rows])
        
        return chat_history

active_connections: Dict[str, WebSocket] = {}

@app.websocket("/ws/{username}")
async def websocket_endpoint(websocket: WebSocket, username: str):
    print(f"🔗 New WebSocket connection: {username}")

    await websocket.accept()
    active_connections[username] = websocket  # Store user connection

    try:
        with sqlite3.connect("chat.db") as conn:
            while True:
                data = await websocket.receive_json()
                recipient, message = data.get("to"), data.get("message")
                timestamp = int(time.time())

                if message.startswith("@payment"):
                    try:
                        _, coinId, amount, address = message.split(",")

                        # Verify Address
                        try:
                            receiver_username, coin_id = address.split("_")
                        except ValueError:
                            await websocket.send_json({"error": "Invalid payment address format"})
                            continue

                        cursor = conn.cursor()
                        print(message, receiver_username, coin_id)
                        print(receiver_username,coin_id)
                        cursor.execute("SELECT id FROM users WHERE username = ?", (receiver_username,))
                        user_row = cursor.fetchone()
                        print()
                        if not user_row or coinId != coin_id:
                            await websocket.send_json({"error": "Invalid payment address"})
                            continue

                        # Check user's balance for the specified coin
                        cursor.execute('''
                            SELECT quantity
                            FROM user_coins 
                            WHERE user_id = (SELECT id FROM users WHERE username = ?) AND coin_id = ?
                        ''', (username ,coinId))
                        balance_row = cursor.fetchone()
                        if not balance_row or not balance_row[0] or float(balance_row[0]) < float(amount):
                            print(2)
                            await websocket.send_json({"error": f"Insufficient balance. Available {balance_row[0]}"})
                            continue

                        # Update user's balance by deducting the payment amount
                        cursor.execute('''
                            UPDATE user_coins 
                            SET quantity = quantity - ?
                            WHERE user_id = (SELECT id FROM users WHERE username = ?) AND coin_id = ?
                        ''', (float(amount), username, coinId))
                        conn.commit()

                        # Update recipient's balance by adding the payment amount
                        cursor.execute('''
                            UPDATE user_coins 
                            SET quantity = quantity + ?
                            WHERE user_id = (SELECT id FROM users WHERE username = ?) AND coin_id = ?
                        ''', (float(amount), receiver_username, coinId))
                        conn.commit()

                        cursor.execute("SELECT coinSymbol, coinName, imageUrl FROM coins WHERE id = ?", (coinId,))
                        coinSymbol, coinName, coinImage  = cursor.fetchone()
                        message = f"@payment,{coinImage},{coinName},{coinSymbol},{amount}"

                    except Exception as e:
                        print(f"⚠️ Payment processing error: {e}")
                        await websocket.send_json({"error": {e}})
                        continue

                try:
                    conn.execute(
                        "INSERT INTO chats (from_user, to_user, message, timestamp) VALUES (?, ?, ?, ?)",
                        (username, recipient, message, timestamp),
                    )
                    conn.commit()
                except sqlite3.Error as e:
                    print(f"⚠️ Database error: {e}")
                    await websocket.send_json({"error": "Failed to save message"})
                    continue
                
                print(f"📩 {username} → {recipient}: {message} | 🕒 {timestamp}")

                try:
                    await websocket.send_json({
                        "from": username,
                        "to": recipient,
                        "message": message,
                        "timestamp": timestamp
                    })
                except Exception as e:
                    print(f"⚠️ Send error to {recipient}: {e}")

                if recipient in active_connections:
                    try:
                        await active_connections[recipient].send_json({
                            "from": username,
                            "to": recipient,
                            "message": message,
                            "timestamp": timestamp
                        })
                    except Exception as e:
                        print(f"⚠️ Send error to {recipient}: {e}")
                else:
                    print(f"⚠️ {recipient} offline")

    except WebSocketDisconnect:
        print(f"❌ {username} disconnected")
    except Exception as e:
        print(f"⚠️ {username} error: {e}")
        await websocket.send_json({"error": str(e)})
    finally:
        active_connections.pop(username, None)


@app.get("/oauthredirect")
def oauth_redirect(code: str, location: str):
    print(f"Received OAuth redirect with code: {code} and location: {location}")
    
    if not code:
        print("Error: Authorization code missing")
        raise HTTPException(status_code=400, detail="Authorization code missing")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host="0.0.0.0", port=4060)





# @app.get("/get_chat_history/{from_user}/{to_user}")
# async def get_chat_history(from_user: str, to_user: str):
#     with sqlite3.connect("chat.db") as conn:
#         cursor = conn.cursor()
#         cursor.execute('''
#             SELECT from_user, to_user, message, timestamp
#             FROM chats 
#             WHERE (from_user = ? AND to_user = ?) OR (to_user = ? AND from_user = ?)
#             ORDER BY timestamp
#         ''', (from_user, to_user, from_user, to_user))

#         rows = cursor.fetchall() 
#         return [{"from": row[0], "to": row[1], "message": row[2], "timestamp": row[3]} 
#                 for row in rows]


# @app.get("/get_user/{username}")
# async def get_user(username: str):
#     with sqlite3.connect("chat.db") as conn:
#         cursor = conn.cursor()
#         cursor.execute("SELECT id FROM users WHERE username = ?", (username,))
#         row = cursor.fetchone()
#         if not row:
#             raise HTTPException(status_code=404, detail="User not found")
#         return {"id": str(row[0])}


