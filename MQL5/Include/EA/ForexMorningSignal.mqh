//+------------------------------------------------------------------+
//|                                           ForexMorningSignal.mqh |
//|                                                         Zephyrrr |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zephyrrr"
#property link      "http://www.mql5.com"

#include <ExpertModel\ExpertModel.mqh>
#include <ExpertModel\ExpertModelSignal.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\DealInfo.mqh>

#include <Indicators\Oscilators.mqh>
#include <Indicators\TimeSeries.mqh>

// GBPUSD, M15
class CForexMorningSignal : public CExpertModelSignal
{
private:
	CiMomentum  m_iMomentum;
	CiCCI m_iCCI;
	CiATR m_iATR;
	CiHigh m_iHigh;
	CiLow m_iLow;

	int CheckMomentum();
	int CheckCCI();
	bool IsLongCandleBefore();

	bool m_checkTimeResultInCheckLong;
	bool CheckTime(bool isBuy);
	bool CheckTime();

	string GetNowStringAccordPeriod();
	string m_lastNow;
	int m_lastDealDay;
	MqlDateTime m_dtStruct;

	bool GetOpenSignal(int wantSignal);

	int m_momentumPeriod, m_cciPeriod, m_atrPeriod, m_momentumLimit;
	bool m_enableCheckLongCandle;

	int m_brokerStopLossPips;   // 发送到服务器的Tp
	int m_brokerProfitTargetPips;
	int m_hiddenStopLossPips;   // 实际的Tp
	int m_hiddenProfitTargetPips;

	int m_checkHour, m_checkMinute;
public:
	CForexMorningSignal();
	~CForexMorningSignal();
	virtual bool      ValidationSettings();
	virtual bool      InitIndicators(CIndicators* indicators);

	virtual bool      CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration);
	virtual bool      CheckCloseLong(CTableOrder* t, double& price);
	virtual bool      CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration);
	virtual bool      CheckCloseShort(CTableOrder* t, double& price);

	void InitParameters(int momentumPeriod, int cciPeriod, int atrPeriod, int momentumLimit, bool enableCheckLongCandle,
		int brokerStopLossPips, int brokerProfitTargetPips, int hiddenStopLossPips, int hiddenProfitTargetPips,
		int checkHour, int checkMinute);
};

void CForexMorningSignal::InitParameters(int momentumPeriod = 60, int cciPeriod = 60, int atrPeriod = 20, int momentumLimit = 80, bool enableCheckLongCandle = true,
	int brokerStopLossPips = 55, int brokerProfitTargetPips = 55, int hiddenStopLossPips = 40, int hiddenProfitTargetPips = 35,
	int checkHour = 7, int checkMinute = 30)
{
	m_momentumPeriod = momentumPeriod;
	m_cciPeriod = cciPeriod;
	m_atrPeriod = atrPeriod;
	m_momentumLimit = momentumLimit;
	m_enableCheckLongCandle = enableCheckLongCandle;

	m_brokerStopLossPips = brokerStopLossPips * GetPointOffset(m_symbol.Digits());;
	m_brokerProfitTargetPips = brokerProfitTargetPips * GetPointOffset(m_symbol.Digits());;
	m_hiddenStopLossPips = hiddenStopLossPips * GetPointOffset(m_symbol.Digits());;
	m_hiddenProfitTargetPips = hiddenProfitTargetPips * GetPointOffset(m_symbol.Digits());;

	m_checkHour = checkHour;
	m_checkMinute = checkMinute;
	
	Debug("brokerStopLossPips=" + IntegerToString(m_brokerStopLossPips) + ",brokerProfitTargetPips=" + IntegerToString(m_brokerProfitTargetPips)
	    + ",hiddenStopLossPips=" + IntegerToString(m_hiddenStopLossPips) + ",hiddenProfitTargetPips=" + IntegerToString(m_hiddenProfitTargetPips));
}

void CForexMorningSignal::CForexMorningSignal()
{
}

void CForexMorningSignal::~CForexMorningSignal()
{
}
bool CForexMorningSignal::ValidationSettings()
{
	if(!CExpertSignal::ValidationSettings()) 
		return(false);

	if(false)
	{
		printf(__FUNCTION__+": Indicators should not be Null!");
		return(false);
	}
	return(true);
}

bool CForexMorningSignal::InitIndicators(CIndicators* indicators)
{
	if(indicators==NULL) 
		return(false);
	bool ret = true;

	ret &= m_iMomentum.Create(m_symbol.Name(), m_period, m_momentumPeriod, PRICE_TYPICAL);
	//m_iMomentum.BufferResize(1000);
	ret &= m_iCCI.Create(m_symbol.Name(), m_period, m_cciPeriod, PRICE_TYPICAL);
	//m_iCCI.BufferResize(1000);
	ret &= m_iATR.Create(m_symbol.Name(), m_period, m_atrPeriod);
	//m_iATR.BufferResize(1000);
	ret &= m_iHigh.Create(m_symbol.Name(), m_period);
	ret &= m_iLow.Create(m_symbol.Name(), m_period);

	ret &= indicators.Add(GetPointer(m_iMomentum));
	ret &= indicators.Add(GetPointer(m_iCCI));
	ret &= indicators.Add(GetPointer(m_iATR));
	ret &= indicators.Add(GetPointer(m_iHigh));
	ret &= indicators.Add(GetPointer(m_iLow));

	return ret;
}

int CForexMorningSignal::CheckMomentum() 
{
	double l_imomentum_0 = m_iMomentum.Main(1);
	double ld_8 = 100.0 * (l_imomentum_0 - 100.0);
	//Print("Momentum ", l_imomentum_0, " : ", ld_8);
	if (MathAbs(ld_8) > m_momentumLimit) 
	{
		//Debug("Momentum is higher/lower than allowed");
		return (0);
	}
	if (ld_8 > 0.0) return (1);
	if (ld_8 < 0.0) return (-1);
	return (0);
}

int CForexMorningSignal::CheckCCI() 
{
	double l_icci_0 = m_iCCI.Main(1);
	//Print("CCI: ", l_icci_0);
	if (l_icci_0 > 0.0) return (1);
	if (l_icci_0 < 0.0) return (-1);
	return (0);
}

string CForexMorningSignal::GetNowStringAccordPeriod()
{
	datetime now = TimeGMT();

	string ret = TimeToString(now, TIME_DATE);
	if (m_period == PERIOD_D1) 
		return (ret);
    
	TimeToStruct(now, m_dtStruct);
	if (m_period == PERIOD_H4 || m_period == PERIOD_H1) 
	{
		ret = ret + IntegerToString(m_dtStruct.hour, 2);
	}
	else if (m_period == PERIOD_M30 || m_period == PERIOD_M15 || m_period == PERIOD_M5 || m_period == PERIOD_M1) 
	{
		ret = TimeToString(now, TIME_DATE | TIME_MINUTES);
	}
	return ret;
}

bool CForexMorningSignal::CheckTime() 
{
	string nows = GetNowStringAccordPeriod();
	if(nows == m_lastNow)
		return false;
	m_lastNow = nows;

    
	int hour = m_dtStruct.hour - GetCETOffset();
	int minute = m_dtStruct.min;
	
	//Print(m_checkHour, ", ", m_checkMinute, ", ", m_lastDealDay, ", ", hour, ", ", minute);
	
	if (hour != m_checkHour || minute != m_checkMinute) 
		return false;
	if (m_dtStruct.day == m_lastDealDay)
		return false;

	return true;
}

bool CForexMorningSignal::CheckTime(bool isBuy) 
{
	if (isBuy)
	{
		m_checkTimeResultInCheckLong = CheckTime();
		return m_checkTimeResultInCheckLong;
	}
	else
	{
		return m_checkTimeResultInCheckLong;
	}
}

bool CForexMorningSignal::IsLongCandleBefore() 
{
	double ld_12;
	double l_iatr_0 = m_iATR.Main(1);
	for (int i = 1; i < 15; i++) 
	{
		ld_12 = m_iHigh.GetData(i) - m_iLow.GetData(i);
		if (ld_12 >= l_iatr_0 * 3) 
			return true;
	}
	return false;
}

bool CForexMorningSignal::GetOpenSignal(int wantSignal) 
{
	int li_ret_0 = CheckMomentum();
	int li_4 = CheckCCI();

	if (li_ret_0 != li_4) 
		return false;

	if (li_ret_0 != 0)
		if (m_enableCheckLongCandle && IsLongCandleBefore()) 
			return false;

	if (wantSignal == 1 && li_ret_0 == 1)
	{
		Debug("CForexMorningSignal Get Open long signal");
		return true;
	}
	else if (wantSignal == -1 && li_ret_0 == -1)
	{
		Debug("CForexMorningSignal Get Open short signal");
		return true;
	}
	return false;
}

bool CForexMorningSignal::CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration)
{
    Debug("CForexMorningSignal::CheckOpenLong");
    
	if (!CheckTime(true))
		return false;

	CExpertModel* em = (CExpertModel *)m_expert;
	if (em.GetOrderCount(ORDER_TYPE_BUY) >= 1)
		return false;

	if (GetOpenSignal(1))
	{
		m_symbol.RefreshRates();

		price = m_symbol.Ask();
		tp = price + m_brokerProfitTargetPips * m_symbol.Point();
		sl = price - m_brokerStopLossPips * m_symbol.Point();

		m_lastDealDay = m_dtStruct.day;

		return true;
	}

	return false;
}

bool CForexMorningSignal::CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration)
{
    Debug("CForexMorningSignal::CheckOpenShort");

	if (!CheckTime(false))
		return false;
    
	CExpertModel* em = (CExpertModel *)m_expert;
	if (em.GetOrderCount(ORDER_TYPE_SELL) >= 1)
		return false;

	if (GetOpenSignal(-1))
	{
		m_symbol.RefreshRates();

		price = m_symbol.Bid();
		tp = price - m_brokerProfitTargetPips * m_symbol.Point();
		sl = price + m_brokerStopLossPips * m_symbol.Point();

		m_lastDealDay = m_dtStruct.day;
		return true;
	}

	return false;
}

bool CForexMorningSignal::CheckCloseLong(CTableOrder* t, double& price)
{
	CExpertModel* em = (CExpertModel *)m_expert;

	if (m_hiddenProfitTargetPips > 0)
	{
		if (m_symbol.Bid() - t.Price() >= m_hiddenProfitTargetPips * m_symbol.Point()) 
		{
			price = m_symbol.Bid();

			Debug("CForexMorningSignal get close long signal1");
			return true;
		}
	}
	if (m_hiddenStopLossPips > 0)
	{
		if (t.Price() - m_symbol.Bid() >= m_hiddenStopLossPips * m_symbol.Point()) 
		{
			price = m_symbol.Bid();

			Debug("CForexMorningSignal get close long signal2");
			return true;
		}
	}

	return false;
}

bool CForexMorningSignal::CheckCloseShort(CTableOrder* t, double& price)
{
	CExpertModel* em = (CExpertModel *)m_expert;

	if (m_hiddenProfitTargetPips > 0)
	{
		if (t.Price() - m_symbol.Ask() >= m_hiddenProfitTargetPips * m_symbol.Point()) 
		{
			price = m_symbol.Ask();

			Debug("CForexMorningSignal get close short signal1");
			return true;
		}
	}     
	if (m_hiddenStopLossPips > 0)
	{
		if (m_symbol.Ask() - t.Price() >= m_hiddenStopLossPips * m_symbol.Point()) 
		{
			price = m_symbol.Ask();

			Debug("CForexMorningSignal get close short signal1");
			return true;
		}
	}

    return false;
}
