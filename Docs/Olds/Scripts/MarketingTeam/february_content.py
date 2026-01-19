import os
import sys
from crewai import Agent, Task, Crew, Process

# Check for API Keys
if "OPENAI_API_KEY" not in os.environ:
    # Attempt to load from .env manually if not set
    try:
        with open('.env') as f:
            for line in f:
                if line.startswith('OPENAI_API_KEY'):
                    key = line.strip().split('=')[1].strip().strip('"').strip("'")
                    os.environ["OPENAI_API_KEY"] = key
    except Exception:
        pass

if "OPENAI_API_KEY" not in os.environ:
    print("WARNING: OPENAI_API_KEY is not set. The script might fail.")

# --- HELPER: Load Local Context ---
def load_file_content(filepath):
    """Safely reads a markdown file and returns its content. Returns empty string if not found."""
    try:
        # Construct absolute path relative to the script location or workspace root
        # Assuming script is in scripts/marketing_team/ and Docs are in Docs/
        # We go up two levels: ../../Docs
        base_path = os.path.dirname(os.path.abspath(__file__))
        workspace_root = os.path.abspath(os.path.join(base_path, '..', '..'))
        full_path = os.path.join(workspace_root, filepath)
        
        if os.path.exists(full_path):
            with open(full_path, 'r', encoding='utf-8') as f:
                return f.read()
        else:
            print(f"WARNING: Context file not found: {full_path}")
            return ""
    except Exception as e:
        print(f"ERROR reading {filepath}: {e}")
        return ""

def create_marketing_crew(topic: str):
    print("...Loading Context from Docs/Marketing/...")
    
    # 1. Load Real Data
    leads_context = load_file_content("Docs/Marketing/leads_full_funnel_analysis.md")
    hybrid_context = load_file_content("Docs/Marketing/hybrid_full_funnel_analysis.md")
    prepayment_context = load_file_content("Docs/Marketing/predoplata_full_funnel_analysis.md")
    voice_context = load_file_content("Docs/Marketing/redakcionnaya_politika.md")
    
    # Combine for Strategy Agent
    full_strategy_context = f"""
    Here is the DATA about our Funnels. Use this to make data-driven decisions.
    
    --- LEADS FUNNEL ANALYSIS ---
    {leads_context[:5000]} # Truncated to avoid token limits if too large, but sufficient for summary
    
    --- HYBRID (ISA) FUNNEL ANALYSIS ---
    {hybrid_context[:5000]}
    
    --- PREPAYMENT FUNNEL ANALYSIS ---
    {prepayment_context[:5000]}
    """

    # --- 2. Define Agents (The Team) ---

    head_of_marketing = Agent(
        role='Head of Marketing & Strategy',
        goal='Develop high-level marketing strategies based on REAL DATA and coordination.',
        backstory=f"""You lead a team of AI agents for Kata Academy. 
        Your strategic brain is fed by actual funnel data.
        
        YOU KNOW:
        - That 'Ghosting' is our biggest problem in Prepayment (40% loss).
        - That 'Waiters' (Perspective) in Leads are a goldmine if nurtured.
        - That Hybrid clients fear 'Contract Shock'.
        
        Your job is to direct the execution based on these insights.
        """,
        verbose=True,
        allow_delegation=True
    )

    crm_lead = Agent(
        role='CRM Strategy Lead',
        goal='Maximize Retention and LTV using known metrics.',
        backstory=f"""You design customer journeys.
        You have read the 'leads_full_funnel_analysis.md' and know specifically that 
        we need to nurture 'Waiters' for 60 days.
        You know that Prepayment clients are 'Pragmatic Buyers' who need ROI arguments, not dreams.
        
        Use the DATA provided in tasks to tailor your plans.
        """,
        verbose=True,
        allow_delegation=False
    )

    copywriter = Agent(
        role='Senior Marketing Copywriter',
        goal='Create compelling copy that adheres to Tone of Voice.',
        backstory=f"""You are the voice of Kata Academy.
        
        CRITICAL: You must strictly follow the 'Redakcionnaya Politika'.
        
        TONE OF VOICE CONSTANTS:
        - We are honest (Radical Truth).
        - We do not use 'Success Success' (Infocyganstvo).
        - We speak to smart people (Switchers, 30+ years old).
        
        If you use clichés like "Unique opportunity", you will be fired.
        """,
        verbose=True,
        allow_delegation=False
    )

    crm_marketer = Agent(
        role='CRM Marketing Specialist',
        goal='Craft personalized emails.',
        backstory="""You are the hands of the CRM strategy. Mobile-first mindset.
        You implement the specific 'Nurturing Loops' described in our analytics.
        """,
        verbose=True,
        allow_delegation=False
    )

    manager_critic = Agent(
        role='Marketing Critic & Analyst',
        goal='Critique plans against the Tone of Voice and Data.',
        backstory=f"""Your job is to ensure we don't hallucinate.
        Check against:
        1. Tone of Voice (from Red Policy).
        2. Funnel Reality (don't promise things we can't do).
        
        Reference Content:
        {voice_context[:2000]}
        """,
        verbose=True,
        allow_delegation=False
    )

    # --- 3. Define Tasks (The Process) ---

    # Task 1: Strategy Definition
    strategy_task = Task(
        description=f"""
        The user wants to launch a marketing campaign for: '{topic}'.
        
        CONTEXT DATA:
        {full_strategy_context}
        
        As Head of Marketing, define the Strategy:
        1. Identify which Segment (Switchers, Young Starters, etc.) this campaign targets.
        2. Reference specific insights from our Analysis (e.g. "We need to fix the Ghost rate").
        3. Define 2 emails per week for 4 weeks.
        """,
        expected_output="A Marketing Strategy document referencing real data points.",
        agent=head_of_marketing
    )

    # Task 2: CRM Strategy
    crm_strategy_task = Task(
        description=f"""
        Design a Content Plan for February based on the Strategy.
        Focus on the 'Pragmatic Buyer' or 'Waiters' segments as defined in our docs.
        
        1. Define the theme for each week.
        2. Purpose of each email.
        """,
        expected_output="A Content Calendar for February.",
        agent=crm_lead,
        context=[strategy_task]
    )

    # Task 3: Email Chain Creation
    email_task = Task(
        description=f"""
        Create the ACTUAL CONTENT for the 8 emails.
        
        STRICTLY FOLLOW RED POLICY:
        {voice_context[:2000]}
        
        Requirements:
        - 8 emails total.
        - No clichés.
        - Use "You" focus.
        """,
        expected_output="8 full email drafts.",
        agent=copywriter,  # Changed to Copywriter for better text generation
        context=[crm_strategy_task]
    )

    # Task 4: Final Review
    review_task = Task(
        description=f"""
        Review the 8 email drafts.
        1. Do they sound like Kata Academy? (Check Red Policy).
        2. Do they address the 'Ghosting' or 'Price Shock' issues?
        """,
        expected_output="A Critical Review Report.",
        agent=manager_critic,
        context=[strategy_task, crm_strategy_task, email_task]
    )

    # --- 4. Assemble Crew ---
    marketing_crew = Crew(
        agents=[head_of_marketing, crm_lead, copywriter, manager_critic],
        tasks=[strategy_task, crm_strategy_task, email_task, review_task],
        process=Process.sequential,
        verbose=True
    )

    return marketing_crew

if __name__ == "__main__":
    print("## AI Marketing Team Simulation - Context Aware ##")
    print("--------------------------------------------------")
    
    topic = "February Content for Kata Academy: Converting 'Waiters' (Jdun) from the Leads Funnel."
    print(f"Topic: {topic}")
    
    crew = create_marketing_crew(topic)
    result = crew.kickoff()
    
    print("\n\n########################")
    print("## Final Plan ##")
    print("########################\n")
    print(result)
