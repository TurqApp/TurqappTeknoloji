part of 'cikmis_sorular_yil_sectirme.dart';

extension CikmisSorularYilSectirmeActionsPart
    on _CikmisSorularYilSectirmeState {
  void _openSession(BuildContext context, _CikmisSoruSessionOption session) {
    if (_isLanguageOrDirectBranch(widget.sinavTuru)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CikmisSorularBaslik2Secimi(
            anaBaslik: widget.anaBaslik,
            sinavTuru: widget.sinavTuru,
            yil: session.yil,
            sira: session.sira,
          ),
        ),
      );
      return;
    }

    if (widget.sinavTuru == _CikmisSorularYilSectirmeState._undergraduate &&
        widget.baslik2 == _CikmisSorularYilSectirmeState._aGroup) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CikmisSorularBaslik3Secimi(
            anaBaslik: widget.anaBaslik,
            sinavTuru: widget.sinavTuru,
            yil: session.yil,
            baslik2: widget.baslik2,
            sira: session.sira,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CikmisSorularPreview(
          anaBaslik: widget.anaBaslik,
          sinavTuru: widget.sinavTuru,
          yil: session.yil,
          baslik2: _resolvePreviewBaslik2(),
          baslik3: _resolvePreviewBaslik3(),
          sira: session.sira,
        ),
      ),
    );
  }

  String _resolvePreviewBaslik2() {
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._yks &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._tyt) {
      return _CikmisSorularYilSectirmeState._tyt;
    }
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._yks &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._ayt) {
      return _CikmisSorularYilSectirmeState._ayt;
    }
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._dgs &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._dgs) {
      return _CikmisSorularYilSectirmeState._dgs;
    }
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._lgs &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._lgs) {
      return _CikmisSorularYilSectirmeState._lgs;
    }
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._kpss &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._associate) {
      return _CikmisSorularYilSectirmeState._associate;
    }
    return widget.baslik2;
  }

  String _resolvePreviewBaslik3() {
    if (widget.sinavTuru == _CikmisSorularYilSectirmeState._undergraduate &&
        widget.baslik2 ==
            _CikmisSorularYilSectirmeState._generalAbilityCulture) {
      return widget.sinavTuru;
    }
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._yks &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._ydt) {
      return widget.sinavTuru;
    }
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._yks &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._tyt) {
      return _CikmisSorularYilSectirmeState._tyt;
    }
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._yks &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._ayt) {
      return _CikmisSorularYilSectirmeState._ayt;
    }
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._dgs &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._dgs) {
      return _CikmisSorularYilSectirmeState._dgs;
    }
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._lgs &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._lgs) {
      return _CikmisSorularYilSectirmeState._lgs;
    }
    if (widget.anaBaslik == _CikmisSorularYilSectirmeState._kpss &&
        widget.sinavTuru == _CikmisSorularYilSectirmeState._associate) {
      return _CikmisSorularYilSectirmeState._associate;
    }
    return widget.baslik3;
  }
}
