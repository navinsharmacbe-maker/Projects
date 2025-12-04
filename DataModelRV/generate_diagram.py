import os
import base64
from simple_ddl_parser import DDLParser
from pyvis.network import Network

def create_table_svg(table_name, columns):
    """
    Generates a base64 encoded SVG data URI for a table node.
    """
    font_size = 14
    row_height = 24
    char_width = 9 # Approximate width for monospace font
    padding = 10
    
    # Calculate dimensions
    header_width = len(table_name) * char_width + 2 * padding
    
    max_col_len = 0
    max_type_len = 0
    
    for col in columns:
        c_name = str(col.get('name', ''))
        c_type = str(col.get('type', ''))
        max_col_len = max(max_col_len, len(c_name))
        max_type_len = max(max_type_len, len(c_type))
        
    # User requested minimum width: 30 chars for name, 10 for type
    min_col_chars = 30
    min_type_chars = 10
    
    col_width = max(max_col_len, min_col_chars) * char_width + 2 * padding
    type_width = max(max_type_len, min_type_chars) * char_width + 2 * padding
    
    # Ensure minimum widths (pixel based fallback, though chars logic covers it)
    col_width = max(col_width, 50)
    type_width = max(type_width, 50)
    
    content_width = col_width + type_width
    total_width = max(header_width, content_width)
    
    # Adjust column widths to fill total width
    if total_width > content_width:
        extra = total_width - content_width
        col_width += extra // 2
        type_width += extra - (extra // 2)
        
    total_height = row_height * (len(columns) + 1)
    
    # SVG Construction
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{total_width}" height="{total_height}">
    <style>
        text {{ font-family: monospace; font-size: {font_size}px; fill: black; dominant-baseline: middle; }}
        .header {{ font-weight: bold; text-anchor: middle; }}
        .cell {{ text-anchor: start; }}
        line {{ stroke: black; stroke-width: 1; }}
        rect {{ fill: white; stroke: black; stroke-width: 1; }}
        .header-bg {{ fill: #e0e0e0; }}
    </style>
    <rect x="0.5" y="0.5" width="{total_width-1}" height="{total_height-1}" />
    
    <!-- Header -->
    <rect x="0.5" y="0.5" width="{total_width-1}" height="{row_height}" class="header-bg" />
    <text x="{total_width/2}" y="{row_height/2}" class="header">{table_name}</text>
    <line x1="0" y1="{row_height}" x2="{total_width}" y2="{row_height}" />
    
    <!-- Vertical Separator -->
    <line x1="{col_width}" y1="{row_height}" x2="{col_width}" y2="{total_height}" />
    '''
    
    y = row_height
    for col in columns:
        c_name = str(col.get('name', ''))
        c_type = str(col.get('type', ''))
        
        # Text
        svg += f'<text x="{padding}" y="{y + row_height/2}" class="cell">{c_name}</text>'
        svg += f'<text x="{col_width + padding}" y="{y + row_height/2}" class="cell">{c_type}</text>'
        
        y += row_height
        # Horizontal line below each row
        if y < total_height:
             svg += f'<line x1="0" y1="{y}" x2="{total_width}" y2="{y}" />'

    svg += '</svg>'
    
    encoded = base64.b64encode(svg.encode('utf-8')).decode('utf-8')
    return f"data:image/svg+xml;base64,{encoded}"

def generate_diagram(ddl_file, output_file):
    """
    Parses a DDL file and generates a network diagram using Pyvis.
    """
    try:
        with open(ddl_file, 'r') as f:
            ddl_content = f.read()
    except FileNotFoundError:
        print(f"Error: File not found: {ddl_file}")
        return

    try:
        parser = DDLParser(ddl_content)
        parsed_result = parser.run(group_by_type=True)
    except Exception as e:
        print(f"Error parsing DDL: {e}")
        return

    # Initialize Pyvis Network
    # directed=True to show FK direction
    # User requested white background and black font
    # Reduced height to 600px as requested
    net = Network(height='600px', width='100%', bgcolor='white', font_color='black', directed=True)
    
    # Adjust physics to bring nodes closer
    # User manually updated these values:
    net.barnes_hut(
        gravity=-2000, 
        central_gravity=0.4, 
        spring_length=250, 
        spring_strength=0.05, 
        damping=0.25, 
        overlap=0.2
    )

    tables = parsed_result.get('tables', [])
    
    if not tables:
        print("No tables found in the DDL.")
        return

    # Add nodes (tables)
    for table in tables:
        table_name = table['table_name']
        
        # Generate SVG for the node
        svg_image = create_table_svg(table_name, table['columns'])
        
        # Title for hover info
        columns_info = "<br>".join([f"{col['name']} ({col['type']})" for col in table['columns']])
        title = f"<b>{table_name}</b><br>{columns_info}"
        
        # Use shape='image' with the generated SVG
        net.add_node(table_name, label=' ', title=title, shape='image', image=svg_image)

    # Add edges (relationships)
    for table in tables:
        table_name = table['table_name']
        
        # Check 'constraints' for foreign keys
        if 'constraints' in table:
             constraints = table['constraints']
             # constraints can be a dict with 'references' list or just a list
             references = []
             if isinstance(constraints, dict):
                 references = constraints.get('references', [])
             elif isinstance(constraints, list):
                 # sometimes it's a list of constraints
                 pass 
             
             for ref in references:
                 ref_table = ref.get('table')
                 if ref_table:
                     # Label could be the column name
                     col_name = ref.get('columns', [''])[0]
                     # Explicitly set color to blue
                     net.add_edge(table_name, ref_table, title=f"FK: {col_name}", color='#3388ff')

        # Also check direct 'foreign_keys' if parser put them there
        if 'foreign_keys' in table:
            for fk in table['foreign_keys']:
                ref_table = fk.get('reference_table')
                if ref_table:
                    label = fk.get('columns', [''])[0]
                    net.add_edge(table_name, ref_table, title=f"FK: {label}", color='#3388ff')

    # Save the network
    try:
        net.save_graph(output_file)
        print(f"Diagram successfully generated: {output_file}")
    except Exception as e:
        print(f"Error saving diagram: {e}")

if __name__ == "__main__":
    ddl_file = "complex_ddl.sql"
    output_file = "data_model_diagram.html"
    generate_diagram(ddl_file, output_file)
