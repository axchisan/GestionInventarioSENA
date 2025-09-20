from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from sqlalchemy import desc
from uuid import UUID
from datetime import datetime, timedelta
from typing import Optional, List
import os
import json
from pathlib import Path

from ..database import get_db
from ..models.generated_reports import GeneratedReport
from ..models.users import User
from ..routers.auth import get_current_user
from ..schemas.generated_reports import GeneratedReportCreate, GeneratedReportResponse

router = APIRouter(tags=["reports"])


@router.post("/generate", response_model=GeneratedReportResponse)
async def generate_report(
    report_request: GeneratedReportCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Generate a new report"""
    
    # Create report record
    db_report = GeneratedReport(
        user_id=current_user.id,
        report_type=report_request.report_type,
        title=report_request.title,
        parameters=report_request.parameters,
        file_format=report_request.file_format,
        status="generating"
    )
    
    db.add(db_report)
    db.commit()
    db.refresh(db_report)
    
    # Add background task to generate the actual report file
    background_tasks.add_task(
        _generate_report_file,
        db_report.id,
        report_request.dict(),
        current_user.id
    )
    
    return GeneratedReportResponse.from_orm(db_report)

@router.get("/", response_model=List[GeneratedReportResponse])
def get_user_reports(
    skip: int = 0,
    limit: int = 50,
    report_type: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get user's generated reports"""
    
    query = db.query(GeneratedReport).filter(GeneratedReport.user_id == current_user.id)
    
    if report_type:
        query = query.filter(GeneratedReport.report_type == report_type)
    
    if status:
        query = query.filter(GeneratedReport.status == status)
    
    reports = query.order_by(desc(GeneratedReport.created_at)).offset(skip).limit(limit).all()
    
    return [GeneratedReportResponse.from_orm(report) for report in reports]

@router.get("/{report_id}", response_model=GeneratedReportResponse)
def get_report(
    report_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get specific report details"""
    
    report = db.query(GeneratedReport).filter(
        GeneratedReport.id == report_id,
        GeneratedReport.user_id == current_user.id
    ).first()
    
    if not report:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    
    return GeneratedReportResponse.from_orm(report)

@router.get("/{report_id}/download")
def download_report(
    report_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Download generated report file"""
    
    report = db.query(GeneratedReport).filter(
        GeneratedReport.id == report_id,
        GeneratedReport.user_id == current_user.id
    ).first()
    
    if not report:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    
    if report.status != "completed":
        raise HTTPException(status_code=400, detail="El reporte aún no está listo para descargar")
    
    if not report.file_path or not os.path.exists(report.file_path):
        raise HTTPException(status_code=404, detail="Archivo de reporte no encontrado")
    
    # Update download count
    report.download_count += 1
    db.commit()
    
    # Determine media type based on file format
    media_type_map = {
        "pdf": "application/pdf",
        "excel": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "csv": "text/csv"
    }
    
    media_type = media_type_map.get(report.file_format, "application/octet-stream")
    filename = f"{report.title}.{report.file_format}"
    
    return FileResponse(
        path=report.file_path,
        media_type=media_type,
        filename=filename
    )

@router.delete("/{report_id}")
def delete_report(
    report_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete a generated report"""
    
    report = db.query(GeneratedReport).filter(
        GeneratedReport.id == report_id,
        GeneratedReport.user_id == current_user.id
    ).first()
    
    if not report:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    
    # Delete file if exists
    if report.file_path and os.path.exists(report.file_path):
        try:
            os.remove(report.file_path)
        except OSError:
            pass  # File might be in use or already deleted
    
    # Delete database record
    db.delete(report)
    db.commit()
    
    return {"message": "Reporte eliminado exitosamente"}

@router.get("/stats/summary")
def get_reports_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get summary statistics for user's reports"""
    
    # Total reports
    total_reports = db.query(GeneratedReport).filter(
        GeneratedReport.user_id == current_user.id
    ).count()
    
    # Reports by status
    completed_reports = db.query(GeneratedReport).filter(
        GeneratedReport.user_id == current_user.id,
        GeneratedReport.status == "completed"
    ).count()
    
    generating_reports = db.query(GeneratedReport).filter(
        GeneratedReport.user_id == current_user.id,
        GeneratedReport.status == "generating"
    ).count()
    
    failed_reports = db.query(GeneratedReport).filter(
        GeneratedReport.user_id == current_user.id,
        GeneratedReport.status == "failed"
    ).count()
    
    # Reports by type
    report_types = db.query(
        GeneratedReport.report_type,
        db.func.count(GeneratedReport.id).label('count')
    ).filter(
        GeneratedReport.user_id == current_user.id
    ).group_by(GeneratedReport.report_type).all()
    
    # Recent activity (last 30 days)
    thirty_days_ago = datetime.now() - timedelta(days=30)
    recent_reports = db.query(GeneratedReport).filter(
        GeneratedReport.user_id == current_user.id,
        GeneratedReport.created_at >= thirty_days_ago
    ).count()
    
    return {
        "total_reports": total_reports,
        "completed_reports": completed_reports,
        "generating_reports": generating_reports,
        "failed_reports": failed_reports,
        "recent_reports": recent_reports,
        "report_types": [{"type": rt.report_type, "count": rt.count} for rt in report_types]
    }

async def _generate_report_file(report_id: UUID, report_request: dict, user_id: UUID):
    """Background task to generate report file"""
    from ..database import SessionLocal
    
    db = SessionLocal()
    try:
        report = db.query(GeneratedReport).filter(GeneratedReport.id == report_id).first()
        if not report:
            return
        
        try:
            # Create reports directory if it doesn't exist
            reports_dir = Path("generated_reports")
            reports_dir.mkdir(exist_ok=True)
            
            # Generate filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{report.report_type}_{timestamp}.{report.file_format}"
            file_path = reports_dir / filename
            
            # Here you would implement the actual report generation logic
            # For now, we'll create a placeholder file
            await _create_report_file(file_path, report_request, db)
            
            # Update report record
            report.file_path = str(file_path)
            report.file_size = os.path.getsize(file_path) if os.path.exists(file_path) else 0
            report.status = "completed"
            report.generated_at = datetime.now()
            report.expires_at = datetime.now() + timedelta(days=30)  # Reports expire after 30 days
            
            db.commit()
            
        except Exception as e:
            # Mark report as failed
            report.status = "failed"
            db.commit()
            print(f"Error generating report {report_id}: {e}")
            
    finally:
        db.close()

async def _create_report_file(file_path: Path, report_request: dict, db: Session):
    """Create the actual report file based on request parameters"""
    
    report_type = report_request.get("report_type")
    file_format = report_request.get("file_format")
    parameters = report_request.get("parameters", {})
    
    if file_format == "csv":
        await _generate_csv_report(file_path, report_type, parameters, db)
    elif file_format == "excel":
        await _generate_excel_report(file_path, report_type, parameters, db)
    elif file_format == "pdf":
        await _generate_pdf_report(file_path, report_type, parameters, db)
    else:
        raise ValueError(f"Unsupported file format: {file_format}")

async def _generate_csv_report(file_path: Path, report_type: str, parameters: dict, db: Session):
    """Generate CSV report"""
    import csv
    
    # Get data based on report type
    data = await _get_report_data(report_type, parameters, db)
    
    with open(file_path, 'w', newline='', encoding='utf-8') as csvfile:
        if not data:
            csvfile.write("No hay datos disponibles\n")
            return
        
        # Write headers
        headers = list(data[0].keys()) if data else []
        writer = csv.DictWriter(csvfile, fieldnames=headers)
        writer.writeheader()
        
        # Write data
        for row in data:
            writer.writerow(row)

async def _generate_excel_report(file_path: Path, report_type: str, parameters: dict, db: Session):
    """Generate Excel report"""
    import pandas as pd
    
    # Get data based on report type
    data = await _get_report_data(report_type, parameters, db)
    
    if not data:
        # Create empty DataFrame with message
        df = pd.DataFrame({"Mensaje": ["No hay datos disponibles"]})
    else:
        df = pd.DataFrame(data)
    
    # Write to Excel
    with pd.ExcelWriter(file_path, engine='openpyxl') as writer:
        df.to_excel(writer, sheet_name=report_type.title(), index=False)

async def _generate_pdf_report(file_path: Path, report_type: str, parameters: dict, db: Session):
    """Generate PDF report"""
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib import colors
    from reportlab.lib.units import inch
    
    # Get data based on report type
    data = await _get_report_data(report_type, parameters, db)
    
    # Create PDF document
    doc = SimpleDocTemplate(str(file_path), pagesize=A4)
    styles = getSampleStyleSheet()
    story = []
    
    # Title
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=16,
        spaceAfter=30,
        alignment=1  # Center alignment
    )
    
    title = f"Reporte de {report_type.title()}"
    story.append(Paragraph(title, title_style))
    story.append(Spacer(1, 12))
    
    # Generated date
    date_text = f"Generado el: {datetime.now().strftime('%d/%m/%Y %H:%M')}"
    story.append(Paragraph(date_text, styles['Normal']))
    story.append(Spacer(1, 20))
    
    if not data:
        story.append(Paragraph("No hay datos disponibles", styles['Normal']))
    else:
        # Create table
        headers = list(data[0].keys()) if data else []
        table_data = [headers]
        
        for row in data:
            table_data.append([str(row.get(header, '')) for header in headers])
        
        # Create table with styling
        table = Table(table_data)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 8),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(table)
    
    # Build PDF
    doc.build(story)

async def _get_report_data(report_type: str, parameters: dict, db: Session):
    """Get data for report generation based on type and parameters"""
    
    # Import models
    from ..models.inventory_items import InventoryItem
    from ..models.loans import Loan
    from ..models.maintenance_requests import MaintenanceRequest
    from ..models.inventory_checks import InventoryCheck
    from ..models.environments import Environment
    
    # Parse date filters if provided
    start_date = parameters.get('start_date')
    end_date = parameters.get('end_date')
    environment_id = parameters.get('environment_id')
    
    if report_type == "inventory":
        query = db.query(InventoryItem)
        
        if environment_id:
            query = query.filter(InventoryItem.environment_id == environment_id)
        
        items = query.all()
        return [
            {
                "Nombre": item.name,
                "Código": item.internal_code,
                "Categoría": item.category,
                "Estado": item.status,
                "Cantidad": item.quantity,
                "Marca": item.brand or "",
                "Modelo": item.model or "",
                "Ubicación": item.location or ""
            }
            for item in items
        ]
    
    elif report_type == "loans":
        query = db.query(Loan)
        
        if start_date:
            query = query.filter(Loan.start_date >= start_date)
        if end_date:
            query = query.filter(Loan.end_date <= end_date)
        if environment_id:
            query = query.filter(Loan.environment_id == environment_id)
        
        loans = query.all()
        return [
            {
                "Programa": loan.program,
                "Propósito": loan.purpose,
                "Fecha Inicio": loan.start_date.strftime('%Y-%m-%d'),
                "Fecha Fin": loan.end_date.strftime('%Y-%m-%d'),
                "Estado": loan.status,
                "Prioridad": loan.priority
            }
            for loan in loans
        ]
    
    elif report_type == "maintenance":
        query = db.query(MaintenanceRequest)
        
        if start_date:
            query = query.filter(MaintenanceRequest.created_at >= start_date)
        if end_date:
            query = query.filter(MaintenanceRequest.created_at <= end_date)
        if environment_id:
            query = query.filter(MaintenanceRequest.environment_id == environment_id)
        
        requests = query.all()
        return [
            {
                "Título": request.title,
                "Descripción": request.description,
                "Prioridad": request.priority,
                "Estado": request.status,
                "Costo": request.cost or 0,
                "Fecha Creación": request.created_at.strftime('%Y-%m-%d')
            }
            for request in requests
        ]
    
    elif report_type == "audit":
        query = db.query(InventoryCheck)
        
        if start_date:
            query = query.filter(InventoryCheck.check_date >= start_date)
        if end_date:
            query = query.filter(InventoryCheck.check_date <= end_date)
        if environment_id:
            query = query.filter(InventoryCheck.environment_id == environment_id)
        
        checks = query.all()
        return [
            {
                "Fecha": check.check_date.strftime('%Y-%m-%d'),
                "Estado": check.status,
                "Items Totales": check.total_items or 0,
                "Items Buenos": check.items_good or 0,
                "Items Dañados": check.items_damaged or 0,
                "Items Faltantes": check.items_missing or 0
            }
            for check in checks
        ]
    
    return []
