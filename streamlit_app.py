import streamlit as st
import snowflake.connector
import anthropic
import pandas as pd
import plotly.express as px
import os

st.set_page_config(
    page_title="Olist Data Assistant",
    page_icon="🔍",
    layout="wide"
)

# ── Schema context Claude gets ───────────────────────────────
SCHEMA_CONTEXT = """
You are a senior data analyst. You have access to a Snowflake 
data warehouse with these tables in the GOLD schema:

TABLE: gold_revenue_overview
Columns: order_month, customer_state, order_status,
total_orders, unique_customers, total_revenue, avg_order_value,
avg_delivery_days, avg_review_score, on_time_deliveries, on_time_pct
Use for: revenue trends, delivery performance, state comparisons,
monthly analysis

TABLE: gold_seller_rankings  
Columns: seller_id, seller_city, seller_state, total_orders,
total_revenue, avg_review_score, on_time_pct, revenue_rank,
rating_rank, delivery_rank, seller_tier
seller_tier values: 'Elite', 'Strong', 'Average', 'Needs Improvement'
Use for: seller performance, rankings, tier analysis

TABLE: gold_category_insights
Columns: category, total_products, total_orders, total_units_sold,
total_revenue, avg_price, avg_review_score, revenue_per_order
Use for: product categories, pricing analysis, category performance

RULES:
- Write Snowflake SQL only
- Always use GOLD schema: OLIST.GOLD.table_name
- Return SQL only, no explanation, no markdown backticks
- Use LIMIT 500 for row-level queries
- For aggregations no LIMIT needed
"""

def get_snowflake_connection():
    return snowflake.connector.connect(
        account=st.secrets["snowflake"]["account"],
        user=st.secrets["snowflake"]["user"],
        password=st.secrets["snowflake"]["password"],
        warehouse=st.secrets["snowflake"]["warehouse"],
        database=st.secrets["snowflake"]["database"],
        schema="GOLD"
    )

def generate_sql(question: str, conversation_history: list) -> str:
    client = anthropic.Anthropic(
        api_key=st.secrets["anthropic"]["api_key"]
    )
    
    messages = conversation_history + [{
        "role": "user",
        "content": f"Write SQL to answer: {question}\nReturn SQL only."
    }]
    
    response = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=500,
        system=SCHEMA_CONTEXT,
        messages=messages
    )
    
    sql = response.content[0].text.strip()
    sql = sql.replace("```sql", "").replace("```", "").strip()
    return sql

def run_query(sql: str) -> pd.DataFrame:
    conn = get_snowflake_connection()
    df = pd.read_sql(sql, conn)
    conn.close()
    return df

def interpret_result(
    question: str, 
    sql: str, 
    df: pd.DataFrame,
    conversation_history: list
) -> str:
    client = anthropic.Anthropic(
        api_key=st.secrets["anthropic"]["api_key"]
    )
    
    messages = conversation_history + [{
        "role": "user",
        "content": f"""
        Question: "{question}"
        
        Result:
        {df.to_string(index=False, max_rows=20)}
        
        Write 2-3 sentences interpreting this result.
        Be specific — use actual numbers.
        End with one actionable insight.
        """
    }]
    
    response = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=250,
        messages=messages
    )
    return response.content[0].text.strip()

# ── UI ───────────────────────────────────────────────────────
st.title("🔍 Olist Data Assistant")
st.caption("Ask any business question about the Olist e-commerce dataset")

# Initialize conversation memory
if "messages" not in st.session_state:
    st.session_state.messages = []
if "history" not in st.session_state:
    st.session_state.history = []

# Example questions
st.markdown("**Try asking:**")
examples = [
    "What are the top 5 states by total revenue?",
    "Which product categories have the worst reviews?",
    "Who are the top 10 sellers by revenue?",
    "What is the monthly revenue trend?",
    "Which seller tier has the best on-time delivery?",
    "What is the average order value by state?"
]

cols = st.columns(3)
for i, ex in enumerate(examples):
    if cols[i % 3].button(ex, key=f"ex_{i}"):
        st.session_state["prefill"] = ex

# Chat history display
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        if msg["role"] == "user":
            st.write(msg["content"])
        else:
            if "sql" in msg:
                st.code(msg["sql"], language="sql")
            if "data" in msg:
                df = pd.DataFrame(msg["data"])
                st.dataframe(df, use_container_width=True)
                
                # Auto chart
                num_cols = df.select_dtypes(
                    include='number').columns.tolist()
                cat_cols = df.select_dtypes(
                    exclude='number').columns.tolist()
                if num_cols and cat_cols and len(df) > 1:
                    fig = px.bar(
                        df.head(15),
                        x=cat_cols[0],
                        y=num_cols[0],
                        title=f"{num_cols[0]} by {cat_cols[0]}"
                    )
                    st.plotly_chart(fig, use_container_width=True)
            if "interpretation" in msg:
                st.info(f"💡 {msg['interpretation']}")

# Input
question = st.chat_input(
    "Ask a question about the data...",
)

if question:
    # Add user message
    st.session_state.messages.append({
        "role": "user", 
        "content": question
    })
    
    with st.chat_message("user"):
        st.write(question)

    with st.chat_message("assistant"):
        with st.spinner("Generating SQL..."):
            sql = generate_sql(
                question, 
                st.session_state.history
            )
        st.code(sql, language="sql")

        with st.spinner("Running query..."):
            try:
                df = run_query(sql)
                st.dataframe(df, use_container_width=True)

                # Auto chart
                num_cols = df.select_dtypes(
                    include='number').columns.tolist()
                cat_cols = df.select_dtypes(
                    exclude='number').columns.tolist()
                if num_cols and cat_cols and len(df) > 1:
                    fig = px.bar(
                        df.head(15),
                        x=cat_cols[0],
                        y=num_cols[0],
                        title=f"{num_cols[0]} by {cat_cols[0]}"
                    )
                    st.plotly_chart(fig, use_container_width=True)

                with st.spinner("Interpreting..."):
                    interpretation = interpret_result(
                        question, sql, df,
                        st.session_state.history
                    )
                st.info(f"💡 {interpretation}")

                # Save to memory
                st.session_state.history.extend([
                    {"role": "user", "content": question},
                    {"role": "assistant", "content": 
                     f"SQL: {sql}\nResult: {df.head(5).to_string()}"}
                ])

                st.session_state.messages.append({
                    "role": "assistant",
                    "sql": sql,
                    "data": df.to_dict(),
                    "interpretation": interpretation
                })

            except Exception as e:
                st.error(f"Query failed: {e}")
                st.caption("Try rephrasing your question.")